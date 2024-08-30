#!/bin/bash
DEFAULT_XDG_CONF_HOME="$HOME/.config"
DEFAULT_XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DEFAULT_XDG_CONF_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DEFAULT_XDG_DATA_HOME}"

# Load helper functions
source $(dirname $BASH_SOURCE)/functions.sh

function cleanup() {
	kill $SUDO_PID
	exit 0
}

trap cleanup SIGINT SIGTERM

# keep sudo credentials alive in the background
sudo -v
sudo_refresh_loop &
SUDO_PID=$!

determine_target

# Source the main configuration file
if [ -f "default.env" ]; then
	source "default.env"
else
	echo "Configuration file default.env not found!"
	exit 1
fi

export TARGET_DIR="$PWD/platform/$TARGET"
export COMMON_DIR="$PWD/platform/common"

if [ -f "user.env" ]; then
	echo "Found user.env, skipping interactive prompt"
	source "user.env"
else
	ask_yes_no "Do you want to install micro-xrce-dds-agent?" INSTALL_DDS_AGENT
	ask_yes_no "Do you want to install logloader?" INSTALL_LOGLOADER

	if [ "$INSTALL_LOGLOADER" = "y" ]; then

		ask_yes_no "Upload to local Flight Review server only?" UPLOAD_TO_LOCAL_SERVER
		if [ "$UPLOAD_TO_LOCAL_SERVER" = "y" ]; then
			# Setup for local only
			USER_EMAIL=""
			UPLOAD_SERVER="http://$(hostname -f).local:5006"
			UPLOAD_TO_FLIGHT_REVIEW="y"
			PUBLIC_LOGS="y"

		else
			# Setup PX4 server upload settings
			ask_yes_no "Do you want to auto upload to PX4 Flight Review?" UPLOAD_TO_FLIGHT_REVIEW
			if [ "$UPLOAD_TO_FLIGHT_REVIEW" = "y" ]; then
				echo "Please enter your email: "
				read -r USER_EMAIL
				ask_yes_no "Do you want your logs to be public?" PUBLIC_LOGS
			fi
		fi
	fi

	ask_yes_no "Do you want to install rtsp-server?" INSTALL_RTSP_SERVER

	if [ "$TARGET" = "jetson" ]; then
		ask_yes_no "Do you want to install rid-transmitter?" INSTALL_RID_TRANSMITTER
		if [ "$INSTALL_RID_TRANSMITTER" = "y" ]; then
			while true; do
				echo "Enter Manufacturer Code (4 characters, digits and uppercase letters only, no O or I): "
				read -r MANUFACTURER_CODE
				if [[ $MANUFACTURER_CODE =~ ^[A-HJ-NP-Z0-9]{4}$ ]]; then
					break
				else
					echo "Invalid Manufacturer Code. Please try again."
				fi
			done

			while true; do
				echo "Enter Serial Number (1-15 characters, digits and uppercase letters only, no O or I): "
				read -r SERIAL_NUMBER
				if [[ $SERIAL_NUMBER =~ ^[A-HJ-NP-Z0-9]{1,15}$ ]]; then
					break
				else
					echo "Invalid Serial Number. Please try again."
				fi
			done
		fi
	fi

	ask_yes_no "Do you want to install ark-ui?" INSTALL_ARK_UI
	ask_yes_no "Do you want to install the polaris-client-mavlink?" INSTALL_POLARIS

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

########## jetson dependencies ##########
if [ "$TARGET" = "jetson" ]; then
	echo "Installing jetpack"
	sudo apt-get install -y \
		nvidia-jetpack
	echo "Jetpack finished"

	sudo pip3 install \
		Jetson.GPIO \
		smbus2 \
		meson \
		pyserial \
		pymavlink \
		dronecan

########## pi dependencies ##########
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

########## user network control ##########
echo "Giving user network control permissions"
sudo adduser $USER netdev
sudo cp $COMMON_DIR/wifi/99-network.pkla /etc/polkit-1/localauthority/90-mandatory.d/
sudo mkdir -p /etc/polkit-1/rules.d/
sudo cp $COMMON_DIR/wifi/02-network-manager.rules /etc/polkit-1/rules.d/
sudo systemctl restart polkit

########## bash aliases ##########
echo "Adding aliases"
declare -A aliases
aliases[mavshell]="mavlink_shell.py udp:0.0.0.0:14569"
aliases[ll]="ls -alF"
aliases[submodupdate]="git submodule update --init --recursive"
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

########## hotspot-control ##########
cp $COMMON_DIR/services/hotspot-control.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user enable hotspot-control.service
systemctl --user restart hotspot-control.service

########## logloader ##########
if [ "$INSTALL_LOGLOADER" = "y" ]; then
	./setup/install_logloader.sh
	./setup/install_flight_review.sh
fi

########## polaris-client-mavlink ##########
if [ "$INSTALL_POLARIS" = "y" ]; then
	./setup/install_polaris.sh
fi

########## rtsp-server ##########
if [ "$INSTALL_RTSP_SERVER" = "y" ]; then
	./setup/install_rtsp_server.sh
fi

########## rid-transmitter ##########
if [ "$INSTALL_RID_TRANSMITTER" = "y" ]; then
	./setup/install_rid_transmitter.sh
fi

########## ark-ui ##########
if [ "$INSTALL_ARK_UI" = "y" ]; then
	./setup/install_ark_ui.sh
fi

########## jetson specific services -- these services run as root ##########
if [ "$TARGET" = "jetson" ]; then
	echo "Installing Jetson services"
	sudo cp $TARGET_DIR/services/jetson-can.service /etc/systemd/system/
	sudo cp $TARGET_DIR/services/jetson-clocks.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable jetson-can.service jetson-clocks.service
	sudo systemctl restart jetson-can.service jetson-clocks.service
fi

sudo systemctl enable systemd-time-wait-sync.service


duration=$SECONDS
minutes=$(((duration % 3600) / 60))
seconds=$((duration % 60))

echo "Finished, took $minutes min, $seconds sec"
echo "Please reboot your device"

cleanup
