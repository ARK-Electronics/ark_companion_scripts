#!/bin/bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository universe
sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update
sudo apt upgrade
sudo apt install ros-humble-ros-base
sudo apt install ros-dev-tools

# Add to bashrc if necessary
BASHRC="$HOME/.bashrc"
ROS2_SOURCE="source /opt/ros/humble/setup.bash"
exists=$(cat $BASHRC | grep "$ROS2_SOURCE")
if [ -z "$exists" ]; then
	echo $ROS2_SOURCE >> $BASHRC
fi
