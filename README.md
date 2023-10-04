## Getting started
If you're just getting started run the `setup.sh` script. This will install dependencies, configure the system, and build/install and start mavlink-router.

These are the steps if you'd like to do it manually for the sake of understanding.

#### Install dependencies
```
sudo apt update
sudo apt install -y \
		apt-utils \
		gcc-arm-none-eabi \
		python3-pip \
		git \
		ninja-build \
		pkg-config \
		gcc g++ \
		systemd \

sudo pip3 install Jetson.GPIO meson pyserial
```

#### Configure environment
```
sudo systemctl stop nvgetty
sudo systemctl disable nvgetty

sudo apt remove modemmanager -y
sudo usermod -a -G dialout $USER

sudo groupadd -f -r gpio
sudo usermod -a -G gpio $USER

sudo cp 99-gpio.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```
#### Install DDS agent
```
sudo snap install micro-xrce-dds-agent --edge
```

#### Clone, build, install, and start mavlink-router
```
git clone --recurse-submodules https://github.com/mavlink-router/mavlink-router.git
cd mavlink-router
meson setup build .
ninja -C build
sudo ninja -C build install
cd ..
```
#### Copy the files onto the system
```
sudo cp mavlink-router.service /etc/systemd/system/
sudo cp start_mavlink_router_service.sh /usr/bin/
sudo cp enable_vbus_det_pixhawk.py /usr/bin/
sudo cp main.conf /etc/mavlink-router/
```
#### Restart mavlink-router service
```
sudo systemctl stop mavlink-router.service
sudo systemctl disable mavlink-router.service
sudo systemctl daemon-reload
sudo systemctl enable mavlink-router
sudo systemctl start mavlink-router
```

## mavlink-router conf file
See the **main.conf** file for mavlink-router configuration details