#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh
echo "Installing ARK-UI"

# Remove old ark-ui
stop_and_disable_remove_service pilot-portal
stop_and_disable_remove_service ark-ui-backend

# clean up old nginx
sudo rm /etc/nginx/sites-enabled/ark-ui &>/dev/null
sudo rm /etc/nginx/sites-available/ark-ui &>/dev/null

# clean up old frontend files
sudo rm -rf /var/www/ark-ui &>/dev/null

# Clone and build repo
ARK_UI_SRC_DIR="$HOME/code/ark-ui"
sudo rm -rf $ARK_UI_SRC_DIR
git_clone_retry https://github.com/ARK-Electronics/ark-ui.git $ARK_UI_SRC_DIR
pushd .
cd $ARK_UI_SRC_DIR
./install.sh
popd

# nginx config
NGINX_CONFIG_FILE_PATH="/etc/nginx/sites-available/ark-ui"
sudo cp "$ARK_UI_SRC_DIR/ark-ui.nginx" $NGINX_CONFIG_FILE_PATH
DEPLOY_PATH="/var/www/ark-ui"
sudo mkdir -p $DEPLOY_PATH/html
sudo mkdir -p $DEPLOY_PATH/api

# Copy frontend and backend files to deployment path
sudo cp -r $ARK_UI_SRC_DIR/ark-ui/dist/* $DEPLOY_PATH/html/
sudo cp -r $ARK_UI_SRC_DIR/backend/* $DEPLOY_PATH/api/

# Set permissions: www-data owns the path and has read/write permissions
sudo chown -R www-data:www-data $DEPLOY_PATH
sudo chmod -R 755 $DEPLOY_PATH

if [ ! -L /etc/nginx/sites-enabled/ark-ui ]; then
  sudo ln -s $NGINX_CONFIG_FILE_PATH /etc/nginx/sites-enabled/ark-ui
fi

# Remove default configuration
sudo rm /etc/nginx/sites-enabled/default

# To check that it can run
sudo -u www-data stat $DEPLOY_PATH

# Test the configuration and restart
sudo nginx -t
sudo systemctl restart nginx

# Install services as user
install_and_enable_service ark-ui-backend

echo "Finished $(basename $BASH_SOURCE)"
