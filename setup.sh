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

sudo pip3 install Jetson.GPIO meson pyserial pymavlink dronecan

# Configure environment
sudo systemctl stop nvgetty
sudo systemctl disable nvgetty

sudo apt remove modemmanager -y
sudo usermod -a -G dialout $USER

sudo groupadd -f -r gpio
sudo usermod -a -G gpio $USER

sudo cp 99-gpio.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger

# Install DDS agent
sudo snap install micro-xrce-dds-agent --edge

# Clone, build, install, and start mavlink-router
git clone --recurse-submodules https://github.com/mavlink-router/mavlink-router.git
cd mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
cd ..

# Added systemd services
sudo cp services/mavlink-router.service /etc/systemd/system/
sudo cp services/dds-agent.service /etc/systemd/system/
sudo cp services/jetson-clocks.service /etc/systemd/system/
sudo cp services/jetson-can.service /etc/systemd/system/

# Copy files to system
sudo cp start_mavlink_router.sh /usr/bin/
sudo cp vbus_enable.py /usr/bin/
sudo cp vbus_disable.py /usr/bin/
sudo cp start_can_interface.sh /usr/bin/
sudo cp main.conf /etc/mavlink-router/

# Restart mavlink-router service
sudo systemctl daemon-reload
sudo systemctl enable mavlink-router
sudo systemctl start mavlink-router
sudo systemctl enable dds-agent
sudo systemctl start dds-agent
sudo systemctl enable jetson-clocks
sudo systemctl start jetson-clocks
sudo systemctl enable jetson-can
sudo systemctl start jetson-can