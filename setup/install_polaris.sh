#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing polaris-client-mavlink"

# Stop and remove the service
stop_disable_remove_service polaris
stop_disable_remove_service polaris-client-mavlink

# Clean up directories
sudo rm -rf ~/polaris-client-mavlink &>/dev/null
sudo rm -rf ~/code/polaris-client-mavlink &>/dev/null
sudo rm /usr/local/bin/polaris-client-mavlink &>/dev/null
sudo rm /usr/local/bin/polaris &>/dev/null

git_clone_retry https://github.com/ARK-Electronics/polaris-client-mavlink.git ~/code/polaris-client-mavlink

pushd .
cd ~/code/polaris-client-mavlink
make install
sudo ldconfig
popd

# Install the service
install_and_enable_service polaris
