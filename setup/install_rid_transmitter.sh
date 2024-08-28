#!/bin/bash

sudo -v

if [ -n "$TARGET_DIR" ]; then

	if uname -ar | grep tegra; then
		TARGET=jetson
	else
		TARGET=pi
	fi

	export TARGET_DIR="$PWD/platform/$TARGET"
fi

echo "Installing RemoteIDTransmitter"

source $(dirname $BASH_SOURCE)/functions.sh

# Stop and remove the service
systemctl --user stop rid-transmitter &>/dev/null
systemctl --user disable rid-transmitter &>/dev/null
sudo rm /etc/systemd/system/rid-transmitter.service &>/dev/null

# Clean up directories
sudo rm -rf ~/code/RemoteIDTransmitter &>/dev/null

git_clone_retry https://github.com/ARK-Electronics/RemoteIDTransmitter.git ~/code/RemoteIDTransmitter

pushd .
cd ~/code/RemoteIDTransmitter
make install
sudo ldconfig
popd

# Install the service
cp $TARGET_DIR/services/rid-transmitter.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable rid-transmitter.service
systemctl --user restart rid-transmitter.service
