#!/bin/bash
DEFAULT_XDG_CONF_HOME="$HOME/.config"
DEFAULT_XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DEFAULT_XDG_CONF_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DEFAULT_XDG_DATA_HOME}"

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
