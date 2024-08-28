#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh

determine_target

echo "Installing mavlink-router"

# clean up legacy if it exists
stop_disable_remove_service mavlink-router

# remove old config, source, and binary
sudo rm -rf /etc/mavlink-router &>/dev/null
sudo rm -rf ~/code/mavlink-router &>/dev/null
sudo rm /usr/bin/mavlink-routerd &>/dev/null

pushd .
git_clone_retry https://github.com/mavlink-router/mavlink-router.git ~/code/mavlink-router
cd ~/code/mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
popd
mkdir -p $XDG_DATA_HOME/mavlink-router/
cp $TARGET_DIR/main.conf $XDG_DATA_HOME/mavlink-router/main.conf

# Install the service
install_and_enable_service mavlink-router
