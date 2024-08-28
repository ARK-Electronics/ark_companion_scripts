#!/bin/bash
DEFAULT_XDG_CONF_HOME="$HOME/.config"
DEFAULT_XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DEFAULT_XDG_CONF_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DEFAULT_XDG_DATA_HOME}"

sudo -v
source $(dirname $BASH_SOURCE)/functions.sh
echo "Installing ARK-UI"

# Remove old pilot-portal
systemctl --user stop pilot-portal-backend.service &>/dev/null
systemctl --user disable pilot-portal-backend.service &>/dev/null
sudo rm /etc/nginx/sites-enabled/pilot-portal &>/dev/null
sudo rm /etc/nginx/sites-available/pilot-portal &>/dev/null
sudo rm -rf /var/www/pilot-portal &>/dev/null
sudo rm $XDG_CONFIG_HOME/systemd/user/pilot-portal-backend.service &>/dev/null

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
mkdir -p $XDG_CONFIG_HOME/systemd/user/
cp $COMMON_DIR/services/ark-ui-backend.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable ark-ui-backend.service
systemctl --user restart ark-ui-backend.service

echo "Finished $(basename $BASH_SOURCE)"
