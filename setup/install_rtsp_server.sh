#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh

determine_target

echo "Installing rtsp-server"

sudo apt-get install -y  \
	libgstreamer1.0-dev \
	libgstreamer-plugins-base1.0-dev \
	libgstreamer-plugins-bad1.0-dev \
	libgstrtspserver-1.0-dev \
	gstreamer1.0-plugins-ugly \
	gstreamer1.0-tools \
	gstreamer1.0-gl \
	gstreamer1.0-gtk3 \
	gstreamer1.0-rtsp

if [ "$TARGET" = "pi" ]; then
	sudo apt-get install -y gstreamer1.0-libcamera

else
	# Ubuntu 22.04, see antimof/UxPlay#121
	sudo apt remove gstreamer1.0-vaapi
fi

stop_and_disable_remove_service rtsp-server

# clean up legacy if it exists
sudo rm -rf ~/code/rtsp-server &>/dev/null

# Clone, build, and install
git_clone_retry https://github.com/ARK-Electronics/rtsp-server.git ~/code/rtsp-server
pushd .
cd ~/code/rtsp-server
make install
sudo ldconfig
popd

# Install the service
install_and_enable_service rtsp-server
