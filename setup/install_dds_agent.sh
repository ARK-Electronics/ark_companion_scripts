#!/bin/bash
source $(dirname $BASH_SOURCE)/functions.sh

determine_target

echo "Installing micro-xrce-dds-agent"

# clean up legacy if it exists
stop_and_disable_remove_service dds-agent

sudo snap install micro-xrce-dds-agent --edge

# Install the service
install_and_enable_target_service dds-agent
