#!/bin/bash

sudo apt update
sudo apt install apt-utils -y
sudo apt install gcc-arm-none-eabi -y
sudo apt remove modemmanager -y
sudo usermod -a -G dialout $USER
sudo systemctl stop nvgetty
sudo systemctl disable nvgetty

sudo snap install micro-xrce-dds-agent --edge

sudo apt install python3-pip -y
sudo pip3 install Jetson.GPIO
sudo groupadd -f -r gpio
sudo usermod -a -G gpio $USER

sudo cp 99-gpio.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger

sudo apt install git ninja-build pkg-config gcc g++ systemd -y
sudo pip3 install meson

git submodule update --init --recursive
cd mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
cd ..
./install_mavlink_router_service.sh
