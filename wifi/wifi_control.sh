#!/bin/bash

function start_ap_mode {
    echo "Setting up Access Point mode"
    nmcli connection delete "$AP_SSID" &>/dev/null  # Remove existing AP connection profile if exists
    nmcli connection add type wifi ifname wlo1 con-name "$AP_SSID" autoconnect no ssid "$AP_SSID" 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
    nmcli connection modify "$AP_SSID" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$AP_PASSWORD" 802-11-wireless-security.pmf disable
    nmcli connection up "$AP_SSID"
}

function start_station_mode {
    echo "Setting up Station mode"
    nmcli connection delete "$STATION_SSID" &>/dev/null  # Remove existing WiFi connection profile if exists
    nmcli connection add type wifi ifname wlo1 con-name "$STATION_SSID" autoconnect yes ssid "$STATION_SSID"
    nmcli connection modify "$STATION_SSID" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$STATION_PASSWORD"
    nmcli connection up "$STATION_SSID" &
    nmcli_pid=$!

    # Check every second up to 5 seconds if the process is still running
    for i in {1..10}; do
        if ps -p $nmcli_pid > /dev/null; then
            if [ $i -eq 5 ]; then
                echo "Connection attempt taking too long, terminating..."
                kill $nmcli_pid
                echo "Connection failed" >&2
                return 1
            fi
            sleep 1
        else
            echo "Connected to WiFi"
            return 0
        fi
    done
}

# Source the environment variables
source /etc/profile.d/ark_env.sh

if [ "$MODE" = "ap" ]; then
    start_ap_mode
else
    if ! start_station_mode; then
        start_ap_mode
    fi
fi
