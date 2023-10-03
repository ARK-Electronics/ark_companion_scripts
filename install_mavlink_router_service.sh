#!/bin/bash

# Enable mavlink usb stream first
sudo cp enable_vbus_det_pixhawk.py /usr/bin/
sudo cp main.conf /etc/mavlink-router/

sudo systemctl stop mavlink-router.service
sudo systemctl disable mavlink-router.service
sudo cp mavlink-router.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mavlink-router
sudo systemctl start mavlink-router