#!/bin/bash
DEFAULT_XDG_CONF_HOME="$HOME/.config"
DEFAULT_XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DEFAULT_XDG_CONF_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DEFAULT_XDG_DATA_HOME}"

sudo -v
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing polaris-client-mavlink"

# Stop and remove the service
systemctl --user stop polaris-client-mavlink &>/dev/null
systemctl --user disable polaris-client-mavlink &>/dev/null
sudo rm /etc/systemd/system/polaris-client-mavlink.service &>/dev/null

# Clean up directories
sudo rm -rf ~/polaris-client-mavlink &>/dev/null
sudo rm -rf ~/code/polaris-client-mavlink &>/dev/null

git_clone_retry https://github.com/ARK-Electronics/polaris-client-mavlink.git ~/code/polaris-client-mavlink

pushd .
cd ~/code/polaris-client-mavlink
make install
sudo ldconfig
popd

# Install the service
cp $COMMON_DIR/services/polaris.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable polaris.service
systemctl --user restart polaris.service
