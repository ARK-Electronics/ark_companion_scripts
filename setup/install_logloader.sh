#!/bin/bash

sudo true
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing logloader"

# clean up legacy if it exists
sudo systemctl stop logloader &>/dev/null
sudo systemctl disable logloader &>/dev/null
sudo rm -rf ~/logloader &>/dev/null
sudo rm /etc/systemd/system/logloader.service &>/dev/null
sudo rm -rf ~/code/logloader &>/dev/null

git_clone_retry https://github.com/ARK-Electronics/logloader.git ~/code/logloader

pushd .
cd ~/code/logloader
make install
sudo ldconfig
popd

# Install the service
sudo cp $COMMON_DIR/services/logloader.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable logloader.service
systemctl --user restart logloader.service
