#!/bin/bash

# Enable mavlink usb stream first
python3 /home/jetson/ark_jetson_scripts/enable_vbus_det_pixhawk.py

sleep 3

# Start mavlink udp stream
sudo mavlink-routerd -c /home/jetson/ark_jetson_scripts/mavlink-router-usb-config.txt
