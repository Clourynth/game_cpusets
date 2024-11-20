#!/system/bin/sh

# Cetak pesan untuk log Magisk selama instalasi
ui_print ""
ui_print "**************************************"
ui_print "*   Checking device compatibility... *"
ui_print "**************************************"
ui_print ""

# Fungsi untuk memeriksa konfigurasi CPU cluster (1+3+4)
check_cpu_cluster() {
    # Ambil output dari file topology/physical_package_id
    CPU_CLUSTER=$(for i in /sys/devices/system/cpu/cpu*/topology/physical_package_id; do
                    cat $i
                  done)

    # Hitung jumlah core per cluster (0, 1, 2, dan 3)
    CLUSTER_0_COUNT=$(echo "$CPU_CLUSTER" | grep -c "^0$")
    CLUSTER_1_COUNT=$(echo "$CPU_CLUSTER" | grep -c "^1$")
    CLUSTER_2_COUNT=$(echo "$CPU_CLUSTER" | grep -c "^2$")
    CLUSTER_3_COUNT=$(echo "$CPU_CLUSTER" | grep -c "^3$")

    ui_print "  Cluster 0 Core Count: $CLUSTER_0_COUNT"
    ui_print "  Cluster 1 Core Count: $CLUSTER_1_COUNT"
    ui_print "  Cluster 2 Core Count: $CLUSTER_2_COUNT"
    ui_print "  Cluster 3 Core Count: $CLUSTER_3_COUNT"
    ui_print ""

    # Periksa apakah cluster 1+3+4
    if [ "$CLUSTER_0_COUNT" -eq 4 ] && [ "$CLUSTER_1_COUNT" -eq 3 ] && \
       [ "$CLUSTER_2_COUNT" -eq 1 ] && [ "$CLUSTER_3_COUNT" -eq 0 ]; then
        ui_print "- Detected 1+3+4 CPU cluster configuration."
        return 0
    fi

    ui_print "! Unsupported CPU configuration."
    ui_print "! This module requires a 1+3+4 CPU cluster."
    return 1
}

# Fungsi untuk memeriksa apakah Cpuset didukung
check_cpuset() {
    if [ ! -d "/dev/cpuset" ]; then
        ui_print "! Cpuset is not supported on this device/kernel."
        return 1
    else
        ui_print "- Cpuset support detected."
        return 0
    fi
}

# Jalankan semua pengecekan
if ! check_cpu_cluster; then
    exit 1
fi

if ! check_cpuset; then
    exit 1
fi

# Pesan konfirmasi sebelum melanjutkan instalasi
ui_print ""
ui_print "*************************************"
ui_print "*   All checks passed.              *"
ui_print "*   Proceeding with installation... *"
ui_print "*************************************"
ui_print ""
ui_print "  Installation success.         "
ui_print ""
ui_print "  Note: "
ui_print "  You can add games to the list by  "
ui_print "  editing the game_list.txt file  "
ui_print "  located in /storage/emulated/0."
ui_print ""
ui_print "  Github: https://github.com/Clourynth  "
ui_print ""