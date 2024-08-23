#!/bin/bash

sudo true
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing polaris-client-mavlink"

# clean up legacy if it exists
sudo systemctl stop polaris-client-mavlink &>/dev/null
sudo systemctl disable polaris-client-mavlink &>/dev/null
sudo rm -rf ~/polaris-client-mavlink &>/dev/null
sudo rm /etc/systemd/system/polaris-client-mavlink.service &>/dev/null
sudo rm -rf ~/code/polaris-client-mavlink &>/dev/null

git_clone_retry https://github.com/ARK-Electronics/polaris-client-mavlink.git ~/code/polaris-client-mavlink

pushd .
cd ~/code/polaris-client-mavlink
make install
sudo ldconfig
popd

# Install the service
sudo cp $COMMON_DIR/services/polaris.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable polaris.service
systemctl --user restart polaris.service
