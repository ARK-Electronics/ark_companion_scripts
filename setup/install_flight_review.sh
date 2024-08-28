#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh

echo "Installing flight_review"

# Stop and remove the service
stop_and_disable_remove_service flight-review

# Clean up directories
sudo rm -rf ~/code/flight_review &>/dev/null

git_clone_retry https://github.com/PX4/flight_review.git ~/code/flight_review

pushd .
cd ~/code/flight_review

# Install dependencies
sudo apt-get install -y sqlite3 fftw3 libfftw3-dev
pip install -r app/requirements.txt
python3 -m pip install --upgrade pandas scipy matplotlib

# Create user config overrides
touch app/config_user.ini
echo "[general]" >> app/config_user.ini
echo "domain_name = $(hostname -f)/flight-review" >> app/config_user.ini
echo "verbose_output = 1" >> app/config_user.ini
echo "storage_path = /opt/flight_review/data" >> app/config_user.ini

# Copy the app to /opt
sudo mkdir -p /opt/flight_review/app/
sudo cp -r app/* /opt/flight_review/app/

# Make user owner
sudo chown -R $USER:$USER /opt/flight_review

# Initialize database
/opt/flight_review/app/setup_db.py

# Install the service
install_and_enable_service flight-review

popd
