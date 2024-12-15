#!/system/bin/sh

# Fungsi Logging
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Pastikan file log dapat ditulis
    if [ ! -w "$LOG_FILE" ]; then
        echo "[$timestamp] ERROR: Cannot write to log file $LOG_FILE" >&2
        return
    fi
    
    # Tulis pesan log
    echo "[$timestamp] $message" >> "$LOG_FILE"
}


LOG_FILE="/data/media/0/g-cpu.log"

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
    log_message "Log file created at $LOG_FILE"
fi

MAX_LOG_SIZE=1048576 # 1MB

rotate_logs() {
    local file_size=$(stat -c%s "$LOG_FILE")
    if [ "$file_size" -gt "$MAX_LOG_SIZE" ]; then
        # Hapus file log lama
        rm "$LOG_FILE"
        # Buat file log baru
        touch "$LOG_FILE"
        log_message "Log file rotated. Old log discarded."
    fi
}

# Path ke file konfigurasi
GAME_CONFIG="/data/media/0/game_list.txt"
MODULE_GAME_CONFIG="/data/adb/modules/game_cpusets/config/game_list.txt"

APP_CONFIG="/data/media/0/app_list.txt"
MODULE_APP_CONFIG="/data/adb/modules/game_cpusets/config/app_list.txt"

# Path ke file buggy game list (khusus game, tidak digabungkan)
BUGGY_GAME_FILE="/data/adb/modules/game_cpusets/config/buggy_game_implementation_list.txt"

# Fungsi untuk memastikan file konfigurasi ada
ensure_config_file() {
    local INTERNAL_CONFIG="$1"
    local MODULE_CONFIG="$2"
    local CONFIG_NAME="$3"
    
    # Periksa jika file config tidak ada di internal storage
    if [ ! -f "$INTERNAL_CONFIG" ]; then
        if [ -f "$MODULE_CONFIG" ]; then
            # Salin file config dari modul ke internal storage
            cp "$MODULE_CONFIG" "$INTERNAL_CONFIG"
            chmod 644 "$INTERNAL_CONFIG"  # Set permissions after copying
            echo "File config $CONFIG_NAME disalin ke $INTERNAL_CONFIG"
        else
            echo "File config $CONFIG_NAME modul tidak ditemukan!"
            touch "$INTERNAL_CONFIG" # Buat file kosong jika file asli tidak ada
            chmod 644 "$INTERNAL_CONFIG"  # Set permissions for the empty file
        fi
    fi
}

# Pastikan file konfigurasi ada
ensure_config_file "$GAME_CONFIG" "$MODULE_GAME_CONFIG" "game"
ensure_config_file "$APP_CONFIG" "$MODULE_APP_CONFIG" "app"

# Simpan nilai default cpusets
DEFAULT_TOP_APP=$(cat /dev/cpuset/top-app/cpus)
DEFAULT_FOREGROUND=$(cat /dev/cpuset/foreground/cpus)

# Ambil nilai frekuensi maksimum dan minimum yang tersedia dari sistem
DEFAULT_SMALL_CORE_FREQ_MIN=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
DEFAULT_SMALL_CORE_FREQ_MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
DEFAULT_BIG_CORE_FREQ_MIN=$(cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_min_freq)
DEFAULT_BIG_CORE_FREQ_MAX=$(cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_max_freq)

# Ambil nilai frekuensi khusus untuk aplikasi hemat daya
ENERGY_SAVING_SMALL_CORE_FREQ_MAX=$(awk '{print $4}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies)
ENERGY_SAVING_BIG_CORE_FREQ_MAX=$(awk '{print $1}' /sys/devices/system/cpu/cpu4/cpufreq/scaling_available_frequencies)

# Ambil nilai frekuensi khusus untuk proteksi baterai saat di-charge + gaming
SAFE_SMALL_CORE_FREQ_MAX=$(awk '{print $3}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies)
SAFE_BIG_CORE_FREQ_MAX=$(awk '{print $1}' /sys/devices/system/cpu/cpu4/cpufreq/scaling_available_frequencies)

# GPU frekuensi (deteksi dari file freq_table_mhz jika tersedia)
AVAILABLE_GPU_FREQS=$(cat /sys/class/kgsl/kgsl-3d0/freq_table_mhz)

# Konversi daftar frekuensi GPU dari MHz jika tersedia
if [ -n "$AVAILABLE_GPU_FREQS" ]; then
    DEFAULT_GPU_FREQ_MIN=$(echo $AVAILABLE_GPU_FREQS | awk '{print $NF}')
    DEFAULT_GPU_FREQ_MAX=$(echo $AVAILABLE_GPU_FREQS | awk '{print $1}')
else
    DEFAULT_GPU_FREQ_MIN="Unavailable"
    DEFAULT_GPU_FREQ_MAX="Unavailable"
fi

# Nilai untuk konfigurasi game

# Konfigurasi Cpusets game kondisi charging & not charging
GAME_TOP_APP="4-7"
GAME_FOREGROUND="0-3"

# Konfigurasi freq & governor kondisi not charging
GAME_SMALL_CORE_FREQ_MAX=$DEFAULT_SMALL_CORE_FREQ_MAX
GAME_BIG_CORE_FREQ_MAX=$DEFAULT_BIG_CORE_FREQ_MAX
GAME_GPU_FREQ_MAX=$DEFAULT_GPU_FREQ_MAX

GAME_GOVERNOR="performance"

# Konfigurasi Cpusets energy-saving app
ENERGY_SAVING_TOP_APP="0-7"
ENERGY_SAVING_FOREGROUND="0-3"

# Konfigurasi Cpusets charging
CHARGING_TOP_APP="0-5"
CHARGING_FOREGROUND="0-3"

# Governor default
DEFAULT_GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)

# Function to set cpusets
set_cpusets() {
    echo "$1" > /dev/cpuset/top-app/cpus
    echo "$2" > /dev/cpuset/foreground/cpus
}

# Function to set governor
set_governor() {
    for cpu in /sys/devices/system/cpu/cpu{4..7}/cpufreq/scaling_governor; do
        if [ -f "$cpu" ]; then
            echo "$1" > "$cpu"
        fi
    done
}

# Function to set maximum CPU and GPU frequencies for gaming
set_max_freq() {
    # echo "$GAME_SMALL_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    # echo "$GAME_SMALL_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    echo "$GAME_BIG_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
    echo "$GAME_BIG_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
    
    # Set GPU frequencies using MHz format
    if [ "$GAME_GPU_FREQ_MAX" != "Unavailable" ]; then
        echo "$GAME_GPU_FREQ_MAX" > /sys/class/kgsl/kgsl-3d0/min_clock_mhz
        echo "$GAME_GPU_FREQ_MAX" > /sys/class/kgsl/kgsl-3d0/max_clock_mhz
    fi
}

set_powersave_freq() {
    echo "$DEFAULT_SMALL_CORE_FREQ_MIN" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    echo "$ENERGY_SAVING_SMALL_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    echo "$DEFAULT_BIG_CORE_FREQ_MIN" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
    echo "$ENERGY_SAVING_BIG_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
    
    # Reset GPU frequencies using MHz format
    if [ "$DEFAULT_GPU_FREQ_MIN" != "Unavailable" ]; then
        echo "$DEFAULT_GPU_FREQ_MIN" > /sys/class/kgsl/kgsl-3d0/min_clock_mhz
        echo "$DEFAULT_GPU_FREQ_MAX" > /sys/class/kgsl/kgsl-3d0/max_clock_mhz
    fi
}
set_safe_freq() {
    echo "$DEFAULT_SMALL_CORE_FREQ_MIN" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    echo "$SAFE_SMALL_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    echo "$DEFAULT_BIG_CORE_FREQ_MIN" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
    echo "$SAFE_BIG_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
    
    # Reset GPU frequencies using MHz format
    if [ "$DEFAULT_GPU_FREQ_MIN" != "Unavailable" ]; then
        echo "$DEFAULT_GPU_FREQ_MIN" > /sys/class/kgsl/kgsl-3d0/min_clock_mhz
        echo "$DEFAULT_GPU_FREQ_MAX" > /sys/class/kgsl/kgsl-3d0/max_clock_mhz
    fi
}

# Function to reset CPU and GPU frequencies to default
reset_freq() {
    echo "$DEFAULT_SMALL_CORE_FREQ_MIN" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    echo "$DEFAULT_SMALL_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    echo "$DEFAULT_BIG_CORE_FREQ_MIN" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
    echo "$DEFAULT_BIG_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
    
    # Reset GPU frequencies using MHz format
    if [ "$DEFAULT_GPU_FREQ_MIN" != "Unavailable" ]; then
        echo "$DEFAULT_GPU_FREQ_MIN" > /sys/class/kgsl/kgsl-3d0/min_clock_mhz
        echo "$DEFAULT_GPU_FREQ_MAX" > /sys/class/kgsl/kgsl-3d0/max_clock_mhz
    fi
}

# Fungsi untuk mengembalikan konfigurasi default
reset_cpusets() {
    echo "$DEFAULT_TOP_APP" > /dev/cpuset/top-app/cpus
    echo "$DEFAULT_FOREGROUND" > /dev/cpuset/foreground/cpus
}

# Fungsi untuk mengembalikan governor default
reset_governor() {
    for cpu in /sys/devices/system/cpu/cpu{4..7}/cpufreq/scaling_governor; do
        echo "$DEFAULT_GOVERNOR" > "$cpu"
    done
}


# Path ke status pengisian daya
BATTERY_STATUS_FILE="/sys/class/power_supply/battery/status"
CHARGING_STATE="Not Charging"

# Fungsi untuk memeriksa apakah perangkat sedang diisi daya
is_charging() {
    if [ -f "$BATTERY_STATUS_FILE" ]; then
        local status=$(cat "$BATTERY_STATUS_FILE")
        if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
            return 0 # True (sedang diisi daya)
        fi
    fi
    return 1 # False (tidak diisi daya)
}

# Path ke status persentase baterai
BATTERY_CAPACITY_FILE="/sys/class/power_supply/battery/capacity"

# Fungsi untuk memeriksa persentase baterai
get_battery_level() {
    if [ -f "$BATTERY_CAPACITY_FILE" ]; then
        cat "$BATTERY_CAPACITY_FILE"
    else
        echo "0" # Default jika file tidak ditemukan
    fi
}

# Monitor dan atur cpusets, governor, dan frekuensi CPU serta GPU
PREVIOUS_APP=""
CHARGING_STATE=""
IS_CONFIG_APPLIED=false

loop_counter=0
LOG_INTERVAL=10

# Jeda setelah booting agar tidak menghambat kecepatan startup OS
sleep 30

while true; do
    # Memanggil rotate_logs setiap LOG_INTERVAL detik
    if (( loop_counter % LOG_INTERVAL == 0 )); then
        rotate_logs
    fi
    ((loop_counter++))
    
    # Periksa apakah perangkat sedang diisi daya
    if is_charging; then
        # Ambil aplikasi yang sedang berjalan
        TOP_APP=$(dumpsys activity activities | grep "topResumedActivity" | awk -F '/' '{print $1}' | awk '{print $NF}')
        
        # Prioritaskan kondisi game saat charging
        if grep -q "$TOP_APP" "$GAME_CONFIG"; then
            if [ "$PREVIOUS_APP" != "$TOP_APP" ] || [ "$IS_CONFIG_APPLIED" = false ]; then
                log_message "Charging: Applying battery protection for game: $TOP_APP"
                set_cpusets "$GAME_TOP_APP" "$GAME_FOREGROUND"
                reset_governor
                set_safe_freq
                IS_CONFIG_APPLIED=true
            fi
        else
            # Jika bukan game, terapkan pengaturan charging default
            if [ "$CHARGING_STATE" != "Charging" ] || [ "$IS_CONFIG_APPLIED" = true ]; then
                log_message "Device is charging. Applying battery protection settings."
                set_cpusets "$CHARGING_TOP_APP" "$CHARGING_FOREGROUND"
                reset_governor
                set_powersave_freq
                CHARGING_STATE="Charging"
                IS_CONFIG_APPLIED=false
            fi
        fi
    else
        # Periksa level baterai
        BATTERY_LEVEL=$(get_battery_level)
        
        if [ "$BATTERY_LEVEL" -lt 20 ]; then
            # Ambil aplikasi yang sedang berjalan
            TOP_APP=$(dumpsys activity activities | grep "topResumedActivity" | awk -F '/' '{print $1}' | awk '{print $NF}')
            
            # Prioritaskan kondisi game saat Low Battery
            if grep -q "$TOP_APP" "$GAME_CONFIG"; then
                if [ "$PREVIOUS_APP" != "$TOP_APP" ] || [ "$IS_CONFIG_APPLIED" = false ]; then
                    log_message "Battery low ($BATTERY_LEVEL%). Applying battery protection for game: $TOP_APP"
                    set_cpusets "$GAME_TOP_APP" "$GAME_FOREGROUND"
                    reset_governor
                    set_safe_freq
                    IS_CONFIG_APPLIED=true
                fi
            else
                # Jika bukan game, terapkan pengaturan hemat daya
                if [ "$CHARGING_STATE" != "Low Battery" ] || [ "$IS_CONFIG_APPLIED" = true ]; then
                    log_message "Battery low ($BATTERY_LEVEL%). Applying power-saving settings."
                    set_cpusets "$ENERGY_SAVING_TOP_APP" "$ENERGY_SAVING_FOREGROUND"
                    reset_governor
                    set_powersave_freq
                    CHARGING_STATE="Low Battery"
                    IS_CONFIG_APPLIED=false
                fi
            fi
            
            # Hentikan iterasi untuk prioritas low battery
            sleep 2
            continue
        else
            if [ "$CHARGING_STATE" != "Not Charging" ]; then
                log_message "Battery level is sufficient ($BATTERY_LEVEL%). Device is not charging. Resetting to normal mode."
                reset_cpusets
                reset_governor
                reset_freq
                CHARGING_STATE="Not Charging"
                IS_CONFIG_APPLIED=false # Reset status aplikasi
            fi
        fi
        
        # Ambil aplikasi yang sedang berjalan
        TOP_APP=$(dumpsys activity activities | grep "topResumedActivity" | awk -F '/' '{print $1}' | awk '{print $NF}')
        
        # Periksa apakah aplikasi adalah game
        IS_BUGGY=false
        if grep -q "$TOP_APP" "$BUGGY_GAME_FILE"; then
            IS_BUGGY=true
            log_message "Buggy game detected: $TOP_APP"
        fi
        
        # Kondisi Tidak charging dan aplikasi adalah game
        if grep -q "$TOP_APP" "$GAME_CONFIG"; then
            if [ "$PREVIOUS_APP" != "$TOP_APP" ] || [ "$IS_CONFIG_APPLIED" = false ]; then
                if [ "$IS_BUGGY" = true ]; then
                    log_message "Waiting 15 seconds for buggy game: $TOP_APP"
                    sleep 15
                fi
                log_message "Not Charging: Applying performance settings for game: $TOP_APP"
                set_cpusets "$GAME_TOP_APP" "$GAME_FOREGROUND"
                set_governor "$GAME_GOVERNOR"
                set_max_freq
                IS_CONFIG_APPLIED=true
            fi
            elif grep -q "$TOP_APP" "$APP_CONFIG"; then
            # Kondisi Tidak charging dan aplikasi hemat daya
            if [ "$PREVIOUS_APP" != "$TOP_APP" ] || [ "$IS_CONFIG_APPLIED" = false ]; then
                # Berikan jeda 10 detik agar tidak menghambat waktu buka aplikasi
                sleep 10
                NEW_TOP_APP=$(dumpsys activity activities | grep "topResumedActivity" | awk -F '/' '{print $1}' | awk '{print $NF}')
                
                # Periksa apakah aplikasi tetap sama setelah jeda
                if [ "$NEW_TOP_APP" = "$TOP_APP" ]; then
                    # Jika aplikasi tetap sama, terapkan pengaturan
                    if [ "$PREVIOUS_APP" != "$NEW_TOP_APP" ] || [ "$IS_CONFIG_APPLIED" = false ]; then
                        log_message "Not Charging: Applying settings for energy-saving app: $NEW_TOP_APP"
                        set_cpusets "$ENERGY_SAVING_TOP_APP" "$ENERGY_SAVING_FOREGROUND"
                        reset_governor
                        set_powersave_freq
                        IS_CONFIG_APPLIED=true
                    fi
                else
                    log_message "Application changed during delay, skipping power-saving settings."
                fi
            fi
        else
            # Kondisi Tidak charging dan aplikasi bukan game atau aplikasi hemat daya
            if [ "$IS_CONFIG_APPLIED" = true ]; then
                log_message "Not Charging: Resetting settings for non-game/non-app: $TOP_APP"
                reset_cpusets
                reset_governor
                reset_freq
                IS_CONFIG_APPLIED=false
            fi
        fi
    fi
    
    # Simpan aplikasi yang sedang berjalan untuk perbandingan pada iterasi berikutnya
    PREVIOUS_APP="$TOP_APP"
    
    # Tunggu sebelum iterasi berikutnya
    sleep 2
done