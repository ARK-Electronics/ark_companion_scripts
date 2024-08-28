#!/bin/bash
DEFAULT_XDG_CONF_HOME="$HOME/.config"
DEFAULT_XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DEFAULT_XDG_CONF_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DEFAULT_XDG_DATA_HOME}"

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
sudo rm -rf /etc/mavlink-router &>/dev/null
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
mkdir -p $XDG_CONFIG_HOME/mavlink-router/
mkdir -p $XDG_DATA_HOME/mavlink-router/
cp $TARGET_DIR/main.conf $XDG_DATA_HOME/mavlink-router/main.conf

# Install the service
cp $TARGET_DIR/services/mavlink-router.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable mavlink-router.service
systemctl --user restart mavlink-router.service
