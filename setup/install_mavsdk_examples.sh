#!/bin/bash

sudo -v
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing mavsdk-examples"
pushd .
sudo rm -rf ~/code/mavsdk-ftp-client &>/dev/null
sudo rm -rf ~/code/mavsdk-examples &>/dev/null
git_clone_retry https://github.com/ARK-Electronics/mavsdk-examples.git ~/code/mavsdk-examples
cd ~/code/mavsdk-examples
make install
popd
