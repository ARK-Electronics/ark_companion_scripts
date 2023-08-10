#!/bin/bash

# Enable mavlink usb stream first
python3 /usr/bin/enable_vbus_det_pixhawk.py

sleep 3

# Start mavlink udp stream
sudo mavlink-routerd -c /usr/bin/mavlink-router-usb-config.txt
