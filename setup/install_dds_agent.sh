#!/bin/bash

sudo -v

if [ -n "$TARGET_DIR" ]; then

	if uname -ar | grep tegra; then
		TARGET=jetson
	else
		TARGET=pi
	fi

	export TARGET_DIR="$PWD/platform/$TARGET"
fi

echo "Installing micro-xrce-dds-agent"

# clean up legacy if it exists
systemctl --user stop dds-agent &>/dev/null
systemctl --user disable dds-agent &>/dev/null
sudo rm /etc/systemd/system/dds-agent.service &>/dev/null

sudo snap install micro-xrce-dds-agent --edge
# Install the service
sudo cp $TARGET_DIR/services/dds-agent.service $XDG_CONFIG_HOME/systemd/user/
systemctl --user daemon-reload
systemctl --user enable dds-agent.service
systemctl --user restart dds-agent.service
