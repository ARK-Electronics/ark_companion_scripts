#!/bin/bash

systemctl stop mavlink-router
./px_uploader.py --port /dev/ttyACM0 /tmp/ark_fmu-v6x_default.px4
systemctl start mavlink-router
