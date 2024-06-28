#!/bin/bash

# Check if a service name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <service-name>"
    exit 1
fi

SERVICE_NAME=$1

# Get the status of the service
ENABLED_STATUS=$(systemctl --user is-enabled $SERVICE_NAME 2>&1)
ACTIVE_STATUS=$(systemctl --user is-active $SERVICE_NAME 2>&1)

# Check for 'Failed to get unit file state' indicating the service does not exist
if [[ "$ENABLED_STATUS" =~ "Failed to get unit file state" ]]; then
    echo "{\"status\": \"error\", \"message\": \"Service not found\"}"
    exit 1
fi

# Generate JSON output
echo "{\"status\": \"success\", \"service\": \"${SERVICE_NAME}\", \"enabled\": \"${ENABLED_STATUS}\", \"active\": \"${ACTIVE_STATUS}\"}"
