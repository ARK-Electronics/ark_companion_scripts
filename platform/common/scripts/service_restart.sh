#!/bin/bash

# This script attempts to restart a specified user service and outputs a JSON structure with the result.
#
# The JSON structure is as follows:
#
# On success:
# {
#     "status": "success",
#     "service": "<service_name>",
#     "active": "<active_status>"
# }
#
# On failure:
# {
#     "status": "fail",
#     "service": "<service_name>",
#     "message": "<error_message>"
# }
#
# - "service": The name of the service that was attempted to be restarted.
# - "active": The active status of the service after the restart attempt ("active", "inactive", etc.).
# - "message": A message indicating the error if the restart failed.
#
# Usage: ./script_name.sh <serviceName>
# Example: ./script_name.sh myService
#
# Exit codes:
# 0 - Success
# 1 - No service name provided
# 2 - Restart command failed

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
