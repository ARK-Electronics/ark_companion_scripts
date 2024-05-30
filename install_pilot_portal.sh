#!/bin/bash

if uname -ar | grep tegra; then
	TARGET=jetson
else
	TARGET=pi
fi

TARGET_DIR="$PWD/platform/$TARGET"
COMMON_DIR="$PWD/platform/common"

# TODO: move this to an install script in tree

# dependencies
sudo apt-get install -y jq nodejs npm nginx
sudo npm install -g @vue/cli

# Clone and build repo
sudo rm -rf ~/code/pilot-portal
git clone --depth=1 https://github.com/ARK-Electronics/pilot-portal.git ~/code/pilot-portal
pushd .
cd ~/code/pilot-portal
PILOT_PORTAL_DIR=$PWD
cd backend
npm install
cd ../pilot-portal
npm install
npm run build
popd

# nginx config
NGINX_CONFIG_FILE_PATH="/etc/nginx/sites-available/pilot-portal"
sudo cp "$PILOT_PORTAL_DIR/pilot-portal.nginx" $NGINX_CONFIG_FILE_PATH
DEPLOY_PATH="/var/www/pilot-portal"
sudo mkdir -p $DEPLOY_PATH/html
sudo mkdir -p $DEPLOY_PATH/api

# Copy frontend and backend files to deployment path
sudo cp -r $PILOT_PORTAL_DIR/pilot-portal/dist/* $DEPLOY_PATH/html/
sudo cp -r $PILOT_PORTAL_DIR/backend/* $DEPLOY_PATH/api/

# Set permissions: www-data owns the path and has read/write permissions
sudo chown -R www-data:www-data $DEPLOY_PATH
sudo chmod -R 755 $DEPLOY_PATH

if [ ! -L /etc/nginx/sites-enabled/pilot-portal ]; then
  sudo ln -s /etc/nginx/sites-available/pilot-portal /etc/nginx/sites-enabled/
fi

# To check that it can run
sudo -u www-data stat $DEPLOY_PATH

# Test the configuration and restart
sudo nginx -t
sudo systemctl restart nginx

# scripts
sudo cp $COMMON_DIR/wifi/*.sh /usr/local/bin

# Add user to netdev and allow networkmanager control
sudo adduser $USER netdev
sudo cp $COMMON_DIR/wifi/99-network.pkla /etc/polkit-1/localauthority/90-mandatory.d/

# If your system uses the newer JavaScript-based .rules method (common in many recent Linux distributions), you should add a .rules file instead:
sudo mkdir -p /etc/polkit-1/rules.d/
sudo cp $COMMON_DIR/wifi/02-network-manager.rules /etc/polkit-1/rules.d/

sudo systemctl restart polkit

# Install services as user
mkdir -p ~/.config/systemd/user/
cp $COMMON_DIR/services/pilot-portal-backend.service ~/.config/systemd/user/
cp $COMMON_DIR/services/hotspot-control.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable pilot-portal-backend.service
systemctl --user enable hotspot-control.service
systemctl --user restart pilot-portal-backend.service

echo "Finished $(basename $BASH_SOURCE)"