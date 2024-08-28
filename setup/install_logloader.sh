#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing logloader"

# Stop and remove the service
stop_and_disable_remove_service logloader

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
install_and_enable_service logloader
