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
		gcc \
		g++ \
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

# Build mavlink-router
pushd .
git clone --recurse-submodules https://github.com/mavlink-router/mavlink-router.git ~/code/mavlink-router
cd ~/code/mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
popd

# Put executables in place
executables=(
	start_mavlink_router.sh
	vbus_enable.py
	vbus_disable.py
	start_can_interface.sh
	px4_set_time.sh
	px4_shell_command.py
)

for e in ${executables[@]}; do
	sudo cp $e /usr/bin/
done

# Put services in place
services=(
	mavlink-router.service
	dds-agent.service
	jetson-clocks.service
	jetson-can.service
	px4-time.service
)

for service in ${services[@]}; do
	sudo cp services/$service /etc/systemd/system/
done

# mavlink-router configuration
sudo cp main.conf /etc/mavlink-router/

# Start services
for service in ${services[@]}; do
	sudo cp services/$f /etc/systemd/system/
	sudo systemctl enable $service && sudo systemctl start $service
done
