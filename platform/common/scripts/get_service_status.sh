#!/bin/bash

# Check if a service name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <service-name>"
    exit 1
fi

SERVICE_NAME=$1

# Get the status of the service
SERVICE_STATUS=$(systemctl --user status $SERVICE_NAME 2>/dev/null)

# Check if systemctl command failed (service does not exist)
if [ $? -ne 0 ]; then
    echo "{\"status\": \"error\", \"message\": \"Service not found\"}"
    exit 1
fi

# Extracting 'Loaded' and 'Active' lines and parse needed details
LOADED_STATUS=$(echo "$SERVICE_STATUS" | grep "Loaded" | awk -F';' '{print $2}' | xargs)
ACTIVE_STATUS=$(echo "$SERVICE_STATUS" | grep "Active" | awk '{print $2}')

# Generate JSON output
echo "{\"status\": \"success\", \"service\": \"${SERVICE_NAME}\", \"loaded\": \"${LOADED_STATUS}\", \"active\": \"${ACTIVE_STATUS}\"}"
