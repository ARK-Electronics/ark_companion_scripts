#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing RemoteIDTransmitter"

# Stop and remove the service
stop_disable_remove_service rid-transmitter

# Clean up directories
sudo rm -rf ~/code/RemoteIDTransmitter &>/dev/null

git_clone_retry https://github.com/ARK-Electronics/RemoteIDTransmitter.git ~/code/RemoteIDTransmitter

pushd .
cd ~/code/RemoteIDTransmitter
make install
sudo ldconfig
popd

add_service_manifest rid-transmitter

# Install the service
install_and_enable_target_service rid-transmitter
