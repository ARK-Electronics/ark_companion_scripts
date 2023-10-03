#!/bin/bash

# Assumes there is a conf file at /etc/mavlink-router/main.conf

# Enable mavlink usb stream first
python3 /usr/bin/enable_vbus_det_pixhawk.py

sleep 1

# sudo mavlink-routerd
