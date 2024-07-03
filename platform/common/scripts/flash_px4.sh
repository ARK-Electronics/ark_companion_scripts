#!/bin/bash

DEFAULT_FW_PATH="/tmp/ark_fmu-v6x_default.px4"
FW_PATH=${1:-$DEFAULT_FW_PATH}

# Check if the firmware file exists
if [ ! -f "$FW_PATH" ]; then
    jq -n --arg msg "Firmware file does not exist" \
          '{status: "failed", message: $msg, percent: 0}'
    exit 1
fi

# Attempt to find the device
SERIALDEVICE=$(ls -l /dev/serial/by-id/*ARK* 2>/dev/null | awk -F'/' '{print "/dev/"$NF}')

if [ -z "$SERIALDEVICE" ]; then
    jq -n --arg msg "ARKV6X not found" \
          '{status: "failed", message: $msg, percent: 0}'
    exit 1
fi

systemctl --user stop mavlink-router &>/dev/null

python3 /usr/local/bin/reset_fmu_wait_bl.py &>/dev/null

# If the device is found and file exists, run the uploader script and filter JSON output
python3 -u /usr/local/bin/px_uploader.py --json-progress --port $SERIALDEVICE $FW_PATH 2>&1 | while IFS= read -r line
do
    echo "$line" | jq -c 'select(type == "object")' 2>/dev/null || :
done

systemctl --user start mavlink-router
