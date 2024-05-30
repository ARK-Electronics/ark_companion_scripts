#!/bin/bash

DEFAULT_FW_PATH=/tmp/ark_fmu-v6x_default.px4
FW_PATH=${1:-$DEFAULT_FW_PATH}

echo "Flashing firmware: $FW_PATH"

if [ ! -f "$FW_PATH" ]; then
    echo "Firmware file does not exist, exiting"
    exit 1
fi

SERIALDEVICE=$(ls -l /dev/serial/by-id/*ARK* | awk -F'/' '{print "/dev/"$NF}')

if [ $? -ne 0 ]; then
    echo "ARKV6X not found, exiting"
    exit 1
fi
echo $SERIALDEVICE

sudo systemctl stop mavlink-router
python3 /usr/local/bin/reset_fmu_wait_bl.py
python3 /usr/local/bin/px_uploader.py --port $SERIALDEVICE $FW_PATH
sudo systemctl start mavlink-router logloader.service
