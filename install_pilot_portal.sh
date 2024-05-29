#!/bin/bash

if uname -ar | grep tegra; then
	TARGET=jetson
else
	TARGET=pi
fi
# TODO: move this to an install script in tree

# dependencies
sudo apt install -y jq nodejs npm nginx
sudo npm install -g @vue/cli axios

# Clone and build repo
sudo rm -rf ~/code/pilot-portal
git clone --depth=1 https://github.com/ARK-Electronics/pilot-portal.git ~/code/pilot-portal
pushd .
cd ~/code/pilot-portal
PILOT_PORTAL_DIR=$PWD
cd pilot-portal
npm install
npm run build
popd

# nginx config
NGINX_CONFIG_FILE="$PILOT_PORTAL_DIR/pilot-portal.nginx"
sed -i "s|/path/to/your/dist|$PILOT_PORTAL_DIR/pilot-portal/dist|g" $NGINX_CONFIG_FILE
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$PILOT_PORTAL_DIR/backend/|" "$TARGET/services/pilot-portal-backend.service"

sudo cp $NGINX_CONFIG_FILE /etc/nginx/sites-available/pilot-portal
if [ ! -L /etc/nginx/sites-enabled/pilot-portal ]; then
  sudo ln -s /etc/nginx/sites-available/pilot-portal /etc/nginx/sites-enabled/
fi
sudo nginx -t  # Test the configuration
sudo systemctl restart nginx

# scripts
sudo cp wifi/*.sh /usr/local/bin

# Add user to netdev and allow networkmanager control
sudo adduser $USER netdev
sudo cp wifi/99-network.pkla /etc/polkit-1/localauthority/90-mandatory.d/

# Install services as user
mkdir -p ~/.config/systemd/user/
cp $TARGET/services/pilot-portal-backend.service ~/.config/systemd/user/
cp $TARGET/services/hotspot-control.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable pilot-portal-backend.service
# TODO: rename to wifi-boot-setup?
systemctl --user enable hotspot-control.service
systemctl --user start pilot-portal-backend.service

echo "Finished"