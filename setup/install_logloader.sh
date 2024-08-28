#!/bin/bash
DEFAULT_XDG_CONF_HOME="$HOME/.config"
DEFAULT_XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DEFAULT_XDG_CONF_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DEFAULT_XDG_DATA_HOME}"

sudo -v
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing logloader"

# Stop and remove the service
systemctl --user stop logloader &>/dev/null
systemctl --user disable logloader &>/dev/null
sudo rm /etc/systemd/system/logloader.service &>/dev/null

# Clean up directories
sudo rm -rf ~/logloader &>/dev/null
sudo rm -rf ~/code/logloader &>/dev/null

git_clone_retry https://github.com/ARK-Electronics/logloader.git ~/code/logloader

pushd .
cd ~/code/logloader
make install
sudo ldconfig
popd

# Install the service
cp $COMMON_DIR/services/logloader.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable logloader.service
systemctl --user restart logloader.service
