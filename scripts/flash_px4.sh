#!/bin/bash
#FW_PATH=/tmp/ark_fmu-v6x_default.px4

# get firmware from command line
FW_PATH=$1

# exit if no firmware path is given
if [ -z "$FW_PATH" ]; then
    echo "No firmware path given"
    exit 1
fi

echo "Flashing firmware: $FW_PATH"

systemctl stop mavlink-router
python3 /usr/bin/reset_fmu_wait_bl.py
python3 /usr/bin/px_uploader.py --port /dev/ttyACM0 $FW_PATH
systemctl start mavlink-router
