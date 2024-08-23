#!/bin/bash

sudo true
source $(dirname $BASH_SOURCE)/functions.sh

pushd .

echo "Installing flight_review"

# clean up legacy if it exists
sudo systemctl stop flight-review &>/dev/null
sudo systemctl disable flight-review &>/dev/null
sudo rm /etc/systemd/system/flight-review.service &>/dev/null
sudo rm -rf ~/code/flight_review &>/dev/null

git_clone_retry https://github.com/PX4/flight_review.git ~/code/flight_review

cd ~/code/flight_review

# install dependencies
sudo apt-get install -y sqlite3 fftw3 libfftw3-dev
pip install -r app/requirements.txt
python3 -m pip install --upgrade pandas scipy matplotlib

# create user config overrides
touch app/config_user.ini
echo "[general]" >> app/config_user.ini
echo "domain_name = jetson.local/flight_review" >> app/config_user.ini
echo "verbose_output = 1" >> app/config_user.ini
echo "storage_path = /opt/flight_review/data" >> app/config_user.ini

# copy the app
sudo mkdir -p /opt/flight_review/app/
sudo cp -r app/* /opt/flight_review/app/

# make user owner
sudo chown -R $USER:$USER /opt/flight_review

# initialize database
/opt/flight_review/app/setup_db.py

# Install the service
sudo cp $COMMON_DIR/services/flight-review.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable flight-review.service
systemctl --user restart flight-review.service

popd
