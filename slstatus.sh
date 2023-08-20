#!/bin/bash

format_bytes() {
    if (($1 > 1000000000)); then
        printf "%.2f GB" "$(bc -l <<<"$1 / 1000000000")"
    elif (($1 > 1000000)); then
        printf "%.2f MB" "$(bc -l <<<"$1 / 1000000")"
    elif (($1 > 1000)); then
        printf "%.2f KB" "$(bc -l <<<"$1 / 1000")"
    else
        echo "${1} B"
    fi
}

wifi_file="/sys/class/net/wlp1s0/statistics"

calculate_transfer_speed() {
    current_rx_bytes=$(cat $wifi_file/rx_bytes)
    current_tx_bytes=$(cat $wifi_file/tx_bytes)

    rx_temp_value=$((current_rx_bytes - initial_rx_bytes))
    tx_temp_value=$((current_tx_bytes - initial_tx_bytes))

    rx_speed=$(format_bytes $rx_temp_value)
    tx_speed=$(format_bytes $tx_temp_value)

    echo "[ r: $rx_speed/s | t: $tx_speed/s]"
}

batteryntemp() {
    local battery=$(cat /sys/class/power_supply/BAT0/capacity)
    local temp=$((($(cat /sys/class/thermal/thermal_zone0/temp) - 10000) / 1000))
    echo "[  $battery% |  $temp°C]"
}

cpuram() {

    #cpu
    read cpu_new user_new nice_new system_new idle_new iowait_new irq_new softirq_new steal_new guest_new guest_nice_new </proc/stat
    total_prev=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
    total_now=$((user_new + nice_new + system_new + idle_new + iowait_new + irq_new + softirq_new + steal_new + guest_new + guest_nice_new))
    total_time=$((total_now - total_prev))
    cpu_usage=$((100 * (total_time - (idle_new - idle)) / total_time))

    #ram
    memory_info=$(free)

    used_memory=$(echo "$memory_info" | grep "Mem:" | awk '{print $3}')
    used_swap=$(echo "$memory_info" | grep "Swap:" | awk '{print $3}')

    total_memory=$(((used_memory + used_swap) * 1000))
    formated_ram=$(format_bytes $total_memory)

    echo "[ $cpu_usage% |  $formated_ram]"
}

dateFormat() {
    date=$(date "+%a %b %d %H:%M:%S")
    echo "[ $date]"
}

while true; do

    transfer_speeds=$(calculate_transfer_speed)
    battery_and_temp=$(batteryntemp)
    cpu_memroy=$(cpuram)
    date=$(dateFormat)

    final_string="$transfer_speeds $battery_and_temp $cpu_memroy $date"

    xsetroot -name "$final_string" -display :0

    initial_rx_bytes=$(cat $wifi_file/rx_bytes)
    initial_tx_bytes=$(cat $wifi_file/tx_bytes)
    read cpu user nice system idle iowait irq softirq steal guest guest_nice </proc/stat

    sleep 1

done
