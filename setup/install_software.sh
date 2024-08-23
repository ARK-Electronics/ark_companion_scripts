#!/bin/bash
DEFAULT_XDG_CONF_HOME="$HOME/.config"
DEFAULT_XDG_DATA_HOME="$HOME/.local/share"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DEFAULT_XDG_CONF_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DEFAULT_XDG_DATA_HOME}"

# Prompt for sudo password at the start to cache it
sudo true
source $(dirname $BASH_SOURCE)/functions.sh

if uname -ar | grep tegra; then
	export TARGET=jetson
else
	export TARGET=pi
fi

export TARGET_DIR="$PWD/platform/$TARGET"
export COMMON_DIR="$PWD/platform/common"
export INSTALL_DDS_AGENT="n"
export INSTALL_RTSP_SERVER="n"
export INSTALL_RID_TRANSMITTER="n"
export MANUFACTURER_CODE="ARK1"
export SERIAL_NUMBER="C0FFEE123"
export INSTALL_LOGLOADER="n"
export INSTALL_POLARIS="n"
export INSTALL_ARK_UI="n"
export POLARIS_API_KEY=""
export USER_EMAIL="logs@arkelectron.com"
export UPLOAD_TO_FLIGHT_REVIEW="n"
export PUBLIC_LOGS="n"

if [ "$#" -gt 0 ]; then
	while [ "$#" -gt 0 ]; do
		case "$1" in
			--install-dds-agent)
				INSTALL_DDS_AGENT="y"
				shift
				;;
			--install-rtsp-server)
				INSTALL_RTSP_SERVER="y"
				shift
				;;
			--install-rid-transmitter)
				INSTALL_RID_TRANSMITTER="y"
				shift
				;;
			--manufacturer-code)
				MANUFACTURER_CODE="$2"
				shift
				;;
			--serial-number)
				SERIAL_NUMBER="$2"
				shift
				;;
			--install-polaris)
				INSTALL_POLARIS="y"
				shift
				;;
			--polaris-api-key)
				POLARIS_API_KEY="$2"
				shift
				;;
			--install-ark-ui)
				INSTALL_ARK_UI="y"
				shift
				;;
			--install-logloader)
				INSTALL_LOGLOADER="y"
				shift
				;;
			--email)
				USER_EMAIL="$2"
				shift 2
				;;
			--auto-upload)
				UPLOAD_TO_FLIGHT_REVIEW="y"
				shift
				;;
			--public-logs)
				PUBLIC_LOGS="y"
				shift
				;;
			-h | --help)
				echo "Usage: $0 [options]"
				echo "Options:"
				echo "  --install-dds-agent         Install micro-xrce-dds-agent"
				echo "  --install-rtsp-server       Install rtsp-server"
				echo "  --install-polaris           Install polaris-client-mavlink"
				echo "    --polaris-api-key         Polaris API key"
				echo "  --install-ark-ui            Install UI interface at $TARGET.local"
				echo "  --install-rid-transmitter   Install RemoteIDTransmitter"
				echo "    --manufacturer-code CODE  Manufacturer code for RemoteID"
				echo "    --serial-number SERIAL    Serial number for RemoteID"
				echo "  --install-logloader         Install logloader"
				echo "    --email EMAIL             Email to use for logloader"
				echo "    --auto-upload             Auto upload logs to PX4 Flight Review"
				echo "    --public-logs             Make logs public on PX4 Flight Review"
				echo "  -h, --help                  Display this help message"
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
		echo "Do you want to auto upload to PX4 Flight Review? (y/n)"
		read -r UPLOAD_TO_FLIGHT_REVIEW
		if [ "$UPLOAD_TO_FLIGHT_REVIEW" = "y" ]; then
			echo "Please enter your email: "
			read -r USER_EMAIL
			echo "Do you want your logs to be public? (y/n)"
			read -r PUBLIC_LOGS
		fi
	fi

	echo "Do you want to install rtsp-server? (y/n)"
	read -r INSTALL_RTSP_SERVER

	if [ "$TARGET" = "jetson" ]; then
		# Pi 4 does not support LE coded phy
		# https://www.argenox.com/library/bluetooth-low-energy/using-raspberry-pi-ble/
		echo "Do you want to install rid-transmitter? (y/n)"
		read -r INSTALL_RID_TRANSMITTER
		if [ "$INSTALL_RID_TRANSMITTER" = "y" ]; then
			echo "Enter Manufacturer Code: "
			read -r MANUFACTURER_CODE
			echo "Enter Serial Number: "
			read -r SERIAL_NUMBER
		fi
	fi

	echo "Do you want to install ark-ui? (y/n)"
	read -r INSTALL_ARK_UI

	echo "Do you want to install the polaris-client-mavlink? (y/n)"
	read -r INSTALL_POLARIS
	if [ "$INSTALL_POLARIS" = "y" ]; then
		if [ -f "polaris.key" ]; then
			read -r POLARIS_API_KEY < polaris.key
			echo "Using API key from polaris.key file"
		else
			echo "Enter API key: "
			read -r POLARIS_API_KEY
		fi
	fi
fi

########## install dependencies ##########
echo "Installing dependencies"
sudo apt-get update
sudo apt-get install -y \
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
		avahi-daemon \
		libssl-dev

if [ "$TARGET" = "jetson" ]; then
	sudo apt-get install -y \
		nvidia-jetpack

	sudo pip3 install \
		Jetson.GPIO \
		smbus2 \
		meson \
		pyserial \
		pymavlink \
		dronecan

elif [ "$TARGET" = "pi" ]; then
	sudo apt-get install python3-RPi.GPIO
	# https://www.raspberrypi.com/documentation/computers/os.html#python-on-raspberry-pi
	sudo pip3 install --break-system-packages \
	pymavlink \
	dronecan
fi

########## configure environment ##########
echo "Configuring environment"
sudo usermod -a -G dialout $USER
sudo groupadd -f -r gpio
sudo usermod -a -G gpio $USER
sudo usermod -a -G i2c $USER
mkdir -p $XDG_CONFIG_HOME/systemd/user/

if [ "$TARGET" = "jetson" ]; then
	sudo systemctl stop nvgetty
	sudo systemctl disable nvgetty
	sudo cp $TARGET_DIR/99-gpio.rules /etc/udev/rules.d/
	sudo udevadm control --reload-rules && sudo udevadm trigger
fi

########## journalctl ##########
echo "Configuring journalctl"
CONF_FILE="/etc/systemd/journald.conf"
if ! grep -q "^Storage=persistent$" "$CONF_FILE"; then
    echo "Storage=persistent" | sudo tee -a "$CONF_FILE" > /dev/null
    echo "Storage=persistent has been added to $CONF_FILE."
else
    echo "Storage=persistent is already set in $CONF_FILE."
fi

sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo chown root:systemd-journal /var/log/journal
sudo chmod 2755 /var/log/journal
sudo systemctl restart systemd-journald
journalctl --disk-usage

########## scripts ##########
echo "Installing scripts"
sudo cp $TARGET_DIR/scripts/* /usr/local/bin
sudo cp $COMMON_DIR/scripts/* /usr/local/bin

########## sudoers permissions ##########
echo "Adding sudoers"
sudo cp $COMMON_DIR/ark_scripts.sudoers /etc/sudoers.d/ark_scripts
sudo chmod 0440 /etc/sudoers.d/ark_scripts
echo "Sudoers entries added successfully."

########## bash aliases ##########
echo "Adding aliases"
declare -A aliases
aliases[mavshell]="mavlink_shell.py udp:0.0.0.0:14569"
aliases[ll]="ls -alF"
aliases[submodupdate]="git submodule update --init --recursive"

# Iterate over the associative array and add each alias if it does not exist
for alias_name in "${!aliases[@]}"; do
	check_and_add_alias "$alias_name" "${aliases[$alias_name]}"
done

########## mavlink-router ##########
./setup/install_mavlink_router.sh

########## dds-agent ##########
if [ "$INSTALL_DDS_AGENT" = "y" ]; then
	./setup/install_dds_agent.sh
fi

########## Always install MAVSDK ##########
./setup/install_mavsdk.sh

########## mavsdk-examples ##########
./setup/install_mavsdk_examples.sh

########## logloader ##########
if [ "$INSTALL_LOGLOADER" = "y" ]; then
	./setup/install_logloader.sh
	./setup/install_flight_review.sh
fi

########## polaris-client-mavlink ##########
if [ "$INSTALL_POLARIS" = "y" ]; then
	./setup/install_polaris.sh
fi

if [ "$INSTALL_RTSP_SERVER" = "y" ]; then
	./setup/install_rtsp_server.sh
fi

if [ "$INSTALL_RID_TRANSMITTER" = "y" ]; then
	./setup/install_rid_transmitter.sh
fi

if [ "$INSTALL_ARK_UI" = "y" ]; then
	./setup/install_ark_ui.sh
fi

# Install jetson specific services -- these services run as root
if [ "$TARGET" = "jetson" ]; then
	echo "Installing Jetson services"
	sudo cp $TARGET_DIR/services/jetson-can.service /etc/systemd/system/
	sudo cp $TARGET_DIR/services/jetson-clocks.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable jetson-can.service jetson-clocks.service
	sudo systemctl restart jetson-can.service jetson-clocks.service
fi

# Enable the time-sync service
sudo systemctl enable systemd-time-wait-sync.service

echo "Finished $(basename $BASH_SOURCE)"
echo "Please reboot your device"
