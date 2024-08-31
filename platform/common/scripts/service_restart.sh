#!/bin/bash

SERVICE_NAME="$1"

# Check if the service name was provided
if [ -z "$SERVICE_NAME" ]; then
    echo "{\"status\": \"fail\", \"message\": \"No service name provided. Usage: $0 <serviceName>\"}"
    exit 1
fi

# Attempt to restart the service
RESTART_OUTPUT=$(systemctl --user restart "$SERVICE_NAME" 2>&1)

# Check if the restart command was successful
if [ $? -eq 0 ]; then
    ACTIVE_STATUS=$(systemctl --user is-active "$SERVICE_NAME" 2>&1)
    echo "{\"status\": \"success\", \"service\": \"$SERVICE_NAME\", \"active\": \"$ACTIVE_STATUS\"}"
else
    echo "{\"status\": \"fail\", \"service\": \"$SERVICE_NAME\", \"message\": \"$RESTART_OUTPUT\"}"
    exit 2
fi
