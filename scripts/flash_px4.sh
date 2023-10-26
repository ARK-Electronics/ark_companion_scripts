#!/bin/bash
FW_PATH=/tmp/ark_fmu-v6x_default.px4

systemctl stop mavlink-router
python3 /usr/bin/reset_fmu_wait_bl.py
python3 /usr/bin/px_uploader.py --port /dev/ttyACM0 $FW_PATH
systemctl start mavlink-router
