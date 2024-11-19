#!/system/bin/sh

# Path ke file config di internal storage
CONFIG_FILE="/data/media/0/game_list.txt"

# Path file config asli di modul
MODULE_CONFIG_FILE="/data/adb/modules/game_cpusets/config/game_list.txt"

# Path ke file buggy game list
BUGGY_GAME_FILE="/data/adb/modules/game_cpusets/config/buggy_game_implementation_list.txt"

# Periksa jika file config tidak ada di internal storage
if [ ! -f "$CONFIG_FILE" ]; then
    if [ -f "$MODULE_CONFIG_FILE" ]; then
        # Salin file config dari modul ke internal storage
        cp "$MODULE_CONFIG_FILE" "$CONFIG_FILE"
        echo "File config disalin ke $CONFIG_FILE"
    else
        echo "File config modul tidak ditemukan!"
        touch "$CONFIG_FILE" # Buat file kosong jika file asli tidak ada
    fi
fi

# Pastikan file memiliki izin yang tepat
chmod 644 "$CONFIG_FILE"

# Ambil nilai default dari sistem
DEFAULT_TOP_APP=$(cat /dev/cpuset/top-app/cpus)
DEFAULT_FOREGROUND=$(cat /dev/cpuset/foreground/cpus)
DEFAULT_SMALL_CORE_FREQ_MIN=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)
DEFAULT_SMALL_CORE_FREQ_MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)
DEFAULT_BIG_CORE_FREQ_MIN=$(cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq)
DEFAULT_BIG_CORE_FREQ_MAX=$(cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq)

# Nilai untuk konfigurasi game
GAME_TOP_APP="4-7"
GAME_FOREGROUND="0-4"
GAME_SMALL_CORE_FREQ_MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
GAME_BIG_CORE_FREQ_MAX=$(cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_max_freq)

# Governor default
DEFAULT_GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)

# Governor performance
GAME_GOVERNOR="performance"

# Function to set cpusets
set_cpusets() {
    echo "$1" > /dev/cpuset/top-app/cpus
    echo "$2" > /dev/cpuset/foreground/cpus
}

# Function to set governor
set_governor() {
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$1" > "$cpu"
    done
}

# Function to set maximum CPU frequency for gaming
set_max_freq() {
    echo "$GAME_SMALL_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    echo "$GAME_BIG_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
}

# Function to reset CPU frequency to default
reset_freq() {
    echo "$DEFAULT_SMALL_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
    echo "$DEFAULT_BIG_CORE_FREQ_MAX" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
}

# Fungsi untuk mengembalikan konfigurasi default
reset_cpusets() {
    echo "$DEFAULT_TOP_APP" > /dev/cpuset/top-app/cpus
    echo "$DEFAULT_FOREGROUND" > /dev/cpuset/foreground/cpus
}

# Fungsi untuk mengembalikan governor default
reset_governor() {
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$DEFAULT_GOVERNOR" > "$cpu"
    done
}

# Monitor dan atur cpusets, governor, dan frekuensi CPU
while true; do
    # Ambil nama aplikasi yang sedang berjalan
    TOP_APP=$(dumpsys activity activities | grep "topResumedActivity" | awk -F '/' '{print $1}' | awk '{print $NF}')

    # Periksa apakah game ada di buggy game list
    IS_BUGGY=false
    if grep -q "$TOP_APP" "$BUGGY_GAME_FILE" && grep -q "$TOP_APP" "$CONFIG_FILE"; then
        IS_BUGGY=true
        echo "Buggy game detected: $TOP_APP"
    fi

    # Jika aplikasi dalam config adalah game
    if grep -q "$TOP_APP" "$CONFIG_FILE"; then
        if [ "$IS_BUGGY" = true ]; then
            echo "Waiting 15 seconds before applying settings for buggy game: $TOP_APP"
            sleep 15
        fi
        set_cpusets "$GAME_TOP_APP" "$GAME_FOREGROUND"
        set_governor "$GAME_GOVERNOR"
        set_max_freq
    else
        # Jika bukan game, kembalikan ke pengaturan default
        reset_cpusets
        reset_governor
        reset_freq
    fi

    # Tunggu sebelum iterasi berikutnya
    sleep 2
done
