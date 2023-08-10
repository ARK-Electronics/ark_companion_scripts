#!/bin/bash

# Enable mavlink usb stream first
sudo cp enable_vbus_det_pixhawk.py /usr/bin/
sudo cp mavlink-router-usb-config.txt /usr/bin/
sudo cp start_mavlink_usb_udp.sh /usr/bin/

sudo systemctl stop mavlink_router.service
sudo systemctl disable mavlink_router.service
sudo cp mavlink_router.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mavlink_router
sudo systemctl start mavlink_router