#!/bin/bash

update_key_value() {
    local file_path=$1
    local key=$2
    local new_value=$3

    # Check if the key exists and has a value
    if grep -q "^${key}=" "$file_path"; then
        # Key exists, replace its value
        sed -i "s/^${key}=.*/${key}=${new_value}/" "$file_path"
    else
        # Key does not exist, add it to the file
        echo "${key}=${new_value}" >> "$file_path"
    fi
}

AP_SSID=$1
AP_PASSWORD=$2
STATION_SSID=$3
STATION_PASSWORD=$4
MODE=$5

# Update environment variables
# we must copy the file to a temporary location to edit, and
# then we can cat it back into the orginal file
echo "updating environment variables"
ARK_ENV_FILE_PATH="/etc/ark.env"
TEMP_FILE="/tmp/ark.env.tmp"
cp $ARK_ENV_FILE_PATH $TEMP_FILE
update_key_value $TEMP_FILE "WIFI_MODE" $MODE
update_key_value $TEMP_FILE "WIFI_AP_SSID" $AP_SSID
update_key_value $TEMP_FILE "WIFI_STATION_SSID" $STATION_SSID
cat $TEMP_FILE >$ARK_ENV_FILE_PATH

# Ensure environment variables are updated
echo "checking updated environment variables"
cat $ARK_ENV_FILE_PATH

# Apply configuration
echo "sourcing environment variables"
source /etc/profile.d/ark_env.sh

if [ "$MODE" = "ap" ]; then
    echo "Setting up Access Point mode"
    nmcli connection delete "$AP_SSID" &>/dev/null  # Remove existing AP connection profile if exists
    nmcli connection add type wifi ifname wlo1 con-name "$AP_SSID" autoconnect no ssid "$AP_SSID" 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
    nmcli connection modify "$AP_SSID" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$AP_PASSWORD" 802-11-wireless-security.pmf disable
    nmcli connection up "$AP_SSID"
else
    echo "Setting up Station mode"
    nmcli connection delete "$STATION_SSID" &>/dev/null  # Remove existing WiFi connection profile if exists
    nmcli connection add type wifi ifname wlo1 con-name "$STATION_SSID" autoconnect yes ssid "$STATION_SSID"
    nmcli connection modify "$STATION_SSID" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$STATION_PASSWORD"
    nmcli connection up "$STATION_SSID" &
    nmcli_pid=$!

    # Check every second up to 5 seconds if the process is still running
    for i in {1..5}; do
        if ps -p $nmcli_pid > /dev/null; then
            if [ $i -eq 5 ]; then
                echo "Connection attempt taking too long, terminating..."
                kill $nmcli_pid
                echo "Connection failed" >&2
                exit 1
            fi
            sleep 1
        else
            echo "Connected to WiFi"
            exit 0
        fi
    done
fi
