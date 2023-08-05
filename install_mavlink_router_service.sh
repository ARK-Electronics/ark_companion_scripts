#!/bin/bash

# Enable mavlink usb stream first
sudo cp mavlink_router.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mavlink_router
sudo systemctl start mavlink_router