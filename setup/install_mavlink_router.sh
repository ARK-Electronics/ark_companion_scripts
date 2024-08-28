#!/bin/bash

sudo -v
source $(dirname $BASH_SOURCE)/functions.sh

if uname -ar | grep tegra; then
	TARGET=jetson
else
	TARGET=pi
fi

TARGET_DIR="$PWD/platform/$TARGET"

echo "Installing mavlink-router"

# clean up legacy if it exists
systemctl --user stop mavlink-router &>/dev/null
systemctl --user disable mavlink-router &>/dev/null
sudo rm /etc/systemd/system/mavlink-router.service &>/dev/null
sudo rm -rf ~/code/mavlink-router &>/dev/null
sudo rm /usr/bin/mavlink-routerd &>/dev/null

pushd .
git_clone_retry https://github.com/mavlink-router/mavlink-router.git ~/code/mavlink-router
cd ~/code/mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
popd
sudo mkdir -p /etc/mavlink-router
cp $TARGET_DIR/main.conf /etc/mavlink-router/

# Install the service
cp $TARGET_DIR/services/mavlink-router.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable mavlink-router.service
systemctl --user restart mavlink-router.service
