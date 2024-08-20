#!/bin/bash

sudo true
source $PWD/functions.sh

pushd .

echo "Installing RemoteIDTransmitter"

# clean up legacy if it exists
sudo systemctl stop rid-transmitter &>/dev/null
sudo systemctl disable rid-transmitter &>/dev/null
sudo rm /etc/systemd/system/rid-transmitter.service &>/dev/null
sudo rm -rf ~/code/RemoteIDTransmitter &>/dev/null

git_clone_retry https://github.com/ARK-Electronics/RemoteIDTransmitter.git ~/code/RemoteIDTransmitter

# Install dependencies
sudo apt-get install -y astyle bluez bluez-tools libbluetooth-dev

cd ~/code/RemoteIDTransmitter

make install

sudo setcap 'cap_net_raw,cap_net_admin+eip' /usr/local/bin/rid-transmitter

sudo ldconfig
popd

# Install the service
sudo cp $COMMON_DIR/services/rid-transmitter.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable rid-transmitter.service
systemctl --user restart rid-transmitter.service
