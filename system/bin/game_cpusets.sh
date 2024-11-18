#!/system/bin/sh

# Path ke file config di internal storage
CONFIG_FILE="/data/media/0/game_list.txt"

# Path file config asli di modul
MODULE_CONFIG_FILE="/data/adb/modules/game_cpusets/config/game_list.txt"

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

# Nilai untuk konfigurasi game
GAME_TOP_APP="4-7"
GAME_FOREGROUND="0-4"

# Function to set cpusets
set_cpusets() {
    echo "$1" > /dev/cpuset/top-app/cpus
    echo "$2" > /dev/cpuset/foreground/cpus
}

# Fungsi untuk mengembalikan konfigurasi default
reset_cpusets() {
    echo "$DEFAULT_TOP_APP" > /dev/cpuset/top-app/cpus
    echo "$DEFAULT_FOREGROUND" > /dev/cpuset/foreground/cpus
}

# Monitor dan atur cpusets
while true; do
    # Ambil nama aplikasi yang sedang berjalan
    TOP_APP=$(dumpsys activity activities | grep "topResumedActivity" | awk -F '/' '{print $1}' | awk '{print $NF}')

    # Jika aplikasi dalam config adalah game, gunakan pengaturan khusus game
    if grep -q "$TOP_APP" "$CONFIG_FILE"; then
        set_cpusets "$GAME_TOP_APP" "$GAME_FOREGROUND"
    else
        # Jika bukan game, kembalikan ke pengaturan default
        reset_cpusets
    fi

    # Tunggu sebelum iterasi berikutnya
    sleep 2
done
