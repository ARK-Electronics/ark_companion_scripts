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
cd backend
npm install
cd ..
npm install
npm run build
popd

# nginx config
NGINX_CONFIG_FILE="$PILOT_PORTAL_DIR/pilot-portal.nginx"
DEPLOY_PATH="/var/www/pilot-portal"
sudo mkdir -p $DEPLOY_PATH/html  # Frontend files
sudo mkdir -p $DEPLOY_PATH/api   # Backend files

sed -i "s|/path/to/your/dist|$DEPLOY_PATH/html/dist|g" $NGINX_CONFIG_FILE
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$DEPLOY_PATH/api|" "$TARGET/services/pilot-portal-backend.service"

# Copy frontend and backend files to deployment path
cp -r $PILOT_PORTAL_DIR/pilot-portal/dist/ $DEPLOY_PATH/html/
cp -r $PILOT_PORTAL_DIR/backend/ $DEPLOY_PATH/api/

# Set permissions
sudo chown -R www-data:www-data $DEPLOY_PATH
sudo chmod -R 755 $DEPLOY_PATH

sudo cp $NGINX_CONFIG_FILE /etc/nginx/sites-available/pilot-portal
if [ ! -L /etc/nginx/sites-enabled/pilot-portal ]; then
  sudo ln -s /etc/nginx/sites-available/pilot-portal /etc/nginx/sites-enabled/
fi

# sudo gpasswd -a www-data $TARGET
# sudo chmod +x /home/
# sudo chmod +x /home/$TARGET
# sudo chmod +x /home/$TARGET/code/pilot-portal/pilot-portal/dist
# sudo chown -R www-data:www-data /home/pi/code/pilot-portal/pilot-portal/dist
# sudo chmod -R 755 /home/$TARGET/code/pilot-portal/pilot-portal/dist

# To check that it can run
sudo -u www-data stat $DEPLOY_PATH

sudo nginx -t  # Test the configuration
sudo systemctl restart nginx

# scripts
sudo cp wifi/*.sh /usr/local/bin

# Add user to netdev and allow networkmanager control
sudo adduser $USER netdev
sudo cp wifi/99-network.pkla /etc/polkit-1/localauthority/90-mandatory.d/
sudo systemctl restart polkit

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