#!/bin/bash

# Assumes there is a conf file here
export MAVLINK_ROUTERD_CONF_FILE="/home/$USER/.local/share/mavlink-router/main.conf"

# Find the correct device path
DEVICE_PATH=$(ls /dev/serial/by-id/*ARK* | grep 'if00')

if [ -z "$DEVICE_PATH" ]; then
    echo "No matching device found for FCUSB endpoint."
    exit 1
fi

# Update the main.conf file with the correct device path for FCUSB
sed -i "s|^Device =.*|Device = $DEVICE_PATH|" "$MAVLINK_ROUTERD_CONF_FILE"

# Enable mavlink usb stream first
python3 ~/.local/bin/vbus_enable.py

sleep 3

mavlink-routerd
