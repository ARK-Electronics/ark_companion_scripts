#!/bin/bash

# Install dependencies
sudo apt update
sudo apt install -y \
		apt-utils \
		gcc-arm-none-eabi \
		python3-pip \
		git \
		ninja-build \
		pkg-config \
		gcc g++ \
		systemd \

sudo pip3 install Jetson.GPIO meson pyserial

# Configure environment
sudo systemctl stop nvgetty
sudo systemctl disable nvgetty

sudo apt remove modemmanager -y
sudo usermod -a -G dialout $USER

sudo groupadd -f -r gpio
sudo usermod -a -G gpio $USER

sudo cp 99-gpio.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger

# TODO: build from source?
sudo snap install micro-xrce-dds-agent --edge

# Clone and build mavlink-router
git clone --recurse-submodules https://github.com/mavlink-router/mavlink-router.git
cd mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
cd ..

sudo cp mavlink-router.service /etc/systemd/system/
sudo cp enable_vbus_det_pixhawk.py /usr/bin/

# Restart mavlink-router service
sudo systemctl stop mavlink_router.service
sudo systemctl disable mavlink_router.service
sudo systemctl daemon-reload
sudo systemctl enable mavlink_router
sudo systemctl start mavlink_router
