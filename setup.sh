#!/bin/bash

# Prompt for sudo password at the start to cache it
sudo true

INSTALL_DDS_AGENT="y"
INSTALL_LOGLOADER="y"
INSTALL_POLARIS="y"
POLARIS_API_KEY=""
USER_EMAIL="logs@arkelectron.com"
UPLOAD_TO_FLIGHT_REVIEW="n"
PUBLIC_LOGS="n"

if [ "$#" -gt 0 ]; then
	# Parse command line arguments
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-d | --install-dds-agent)
				INSTALL_DDS_AGENT="y"
				shift
				;;
			-l | --install-logloader)
				INSTALL_LOGLOADER="y"
				shift
				;;
			-l | --install-polaris)
				INSTALL_POLARIS="y"
				shift
				;;
			-e | --email)
				USER_EMAIL="$2"
				shift 2
				;;
			-u | --upload-to-flight-review)
				UPLOAD_TO_FLIGHT_REVIEW="y"
				shift
				;;
			-p | --public-logs)
				PUBLIC_LOGS="y"
				shift
				;;
			-h | --help)
				echo "Usage: $0 [options]"
				echo "Options:"
				echo "  -d, --install-dds-agent    Install micro-xrce-dds-agent"
				echo "  -l, --install-logloader    Install logloader"
				echo "  -e, --email EMAIL          Email to use for logloader"
				echo "  -u, --upload-to-flight-review  Auto upload logs to PX4 Flight Review"
				echo "  -p, --public-logs          Make logs public on PX4 Flight Review"
				echo "  -h, --help                 Display this help message"
				exit 0
				;;
			*)
				echo "Unknown argument: $1"
				exit 1
				;;
		esac
	done
else
	echo "Do you want to install micro-xrce-dds-agent? (y/n)"
	read -r INSTALL_DDS_AGENT

	echo "Do you want to install logloader? (y/n)"
	read -r INSTALL_LOGLOADER

	if [ "$INSTALL_LOGLOADER" = "y" ]; then
		echo "Please enter your email: "
		read -r USER_EMAIL

		echo "Do you want to auto upload to PX4 Flight Review? (y/n)"
		read -r UPLOAD_TO_FLIGHT_REVIEW
		if [ "$UPLOAD_TO_FLIGHT_REVIEW" = "y" ]; then
			echo "Do you want your logs to be public? (y/n)"
			read -r PUBLIC_LOGS
		fi
	fi

	echo "Do you want to install the polaris-client-mavlink? (y/n)"
	read -r INSTALL_POLARIS
	if [ "$INSTALL_POLARIS" = "y" ]; then
		echo "Enter API key: "
		read -r POLARIS_API_KEY
	fi

fi

if uname -ar | grep tegra; then
	TARGET=jetson
else
	TARGET=pi
fi

########## install dependencies ##########
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
		nano \
		git-lfs \
		cmake \
		astyle \
		curl \
		jq \
		snap \
  		snapd \

sudo pip3 install Jetson.GPIO meson pyserial pymavlink dronecan

########## configure environment ##########
echo "Configuring environment"
sudo systemctl stop nvgetty
sudo systemctl disable nvgetty
sudo apt remove modemmanager -y
sudo usermod -a -G dialout $USER
sudo groupadd -f -r gpio
sudo usermod -a -G gpio $USER
sudo usermod -a -G i2c $USER

if [ "$TARGET" = "jetson" ]; then
	sudo cp $TARGET/99-gpio.rules /etc/udev/rules.d/
	sudo udevadm control --reload-rules && sudo udevadm trigger
fi

########## scripts ##########
echo "Installing scripts"
# Copy scripts to /usr/bin
for file in "${TARGET}/scripts/"*; do
	sudo cp $file /usr/bin
done

# Add some helpful aliases
echo "alias mavshell=\"mavlink_shell.py udp:0.0.0.0:14569\"" >> ~/.bash_aliases

########## mavlink-router ##########
echo "Installing mavlink-router"
sudo rm -rf ~/code/mavlink-router
sudo rm /usr/bin/mavlink-routerd
pushd .
git clone --recurse-submodules --depth=1 --shallow-submodules https://github.com/mavlink-router/mavlink-router.git ~/code/mavlink-router
cd ~/code/mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
popd
sudo mkdir -p /etc/mavlink-router
sudo cp $TARGET/main.conf /etc/mavlink-router/

# Install the service
sudo cp $TARGET/services/mavlink-router.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mavlink-router.service
sudo systemctl restart mavlink-router.service

########## dds-agent ##########
if [ "$INSTALL_DDS_AGENT" = "y" ]; then
	echo "Installing micro-xrce-dds-agent"
	sudo snap install micro-xrce-dds-agent --edge
	# Install the service
	sudo cp $TARGET/services/dds-agent.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable dds-agent.service
	sudo systemctl restart dds-agent.service
else
	echo "micro-xrce-dds-agent already installed"
fi

########## Always install MAVSDK ##########
echo "Downloading the latest release of mavsdk"
release_info=$(curl -s https://api.github.com/repos/mavlink/MAVSDK/releases/latest)
# Assumes arm64
download_url=$(echo "$release_info" | grep "browser_download_url.*arm64.deb" | awk -F '"' '{print $4}')
file_name=$(echo "$release_info" | grep "name.*arm64.deb" | awk -F '"' '{print $4}')

if [ -z "$download_url" ]; then
    echo "Download URL not found for arm64.deb package"
    exit 1
fi

echo "Downloading $download_url..."
curl -sSL "$download_url" -o $(basename "$download_url")

echo "Installing $file_name"
sudo dpkg -i $file_name
sudo rm $file_name

########## mavsdk-ftp-client ##########
echo "Installing mavsdk-ftp-client"
pushd .
sudo rm -rf ~/code/mavsdk-ftp-client
git clone https://github.com/ARK-Electronics/mavsdk-ftp-client.git ~/code/mavsdk-ftp-client
cd ~/code/mavsdk-ftp-client
make install
popd

########## logloader ##########
if [ "$INSTALL_LOGLOADER" = "y" ]; then
	echo "Installing logloader"
	pushd .
	sudo rm -rf ~/code/logloader
	git clone --recurse-submodules --depth=1 --shallow-submodules https://github.com/ARK-Electronics/logloader.git ~/code/logloader
	cd ~/code/logloader
	./upgrade_openssl.sh

	# Modify and install the config file
	CONFIG_FILE=install.config.toml
	cp config.toml $CONFIG_FILE
	sed -i "s/^email = \".*\"/email = \"$USER_EMAIL\"/" "$CONFIG_FILE"

	if [ "$UPLOAD_TO_FLIGHT_REVIEW" = "y" ]; then
	    sed -i "s/^upload_enabled = .*/upload_enabled = true/" "$CONFIG_FILE"
	else
	    sed -i "s/^upload_enabled = .*/upload_enabled = false/" "$CONFIG_FILE"
	fi

	if [ "$PUBLIC_LOGS" = "y" ]; then
	    sed -i "s/^public_logs = .*/public_logs = true/" "$CONFIG_FILE"
	else
	    sed -i "s/^public_logs = .*/public_logs = false/" "$CONFIG_FILE"
	fi

	make install

	popd

	# Install the service
	sudo cp $TARGET/services/logloader.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable logloader.service
	sudo systemctl restart logloader.service
fi

########## polaris-client-mavlink ##########
if [ "$INSTALL_POLARIS" = "y" ]; then
	echo "Installing polaris-client-mavlink"
	pushd .
	sudo rm -rf ~/code/polaris-client-mavlink
	git clone --recurse-submodules --depth=1 --shallow-submodules https://github.com/ARK-Electronics/polaris-client-mavlink.git ~/code/polaris-client-mavlink
	cd ~/code/polaris-client-mavlink

	# Modify and install the config file
	CONFIG_FILE=install.config.toml
	cp config.toml $CONFIG_FILE
	sed -i "s/^polaris_api_key = \".*\"/polaris_api_key = \"$POLARIS_API_KEY\"/" "$CONFIG_FILE"

	make install

	popd
	# Install the service
	sudo cp $TARGET/services/polaris-client-mavlink.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable polaris-client-mavlink.service
	sudo systemctl restart polaris-client-mavlink.service
fi


# Install jetson specific services
if [ "$TARGET" = "jetson" ]; then
	echo "Installing Jetson services"
	sudo cp $TARGET/services/jetson-can.service /etc/systemd/system/
	sudo cp $TARGET/services/jetson-clocks.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable jetson-can.service jetson-clocks.service
	sudo systemctl restart jetson-can.service jetson-clocks.service
fi

# Enable the time-sync service
sudo systemctl enable systemd-time-wait-sync.service

echo "Finished"
