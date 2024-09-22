#!/bin/bash

# This script attempts to stop a specified user service and outputs a JSON structure with the result.
#
# The JSON structure is as follows:
#
# On success:
# {
#     "status": "success",
#     "service": "<service_name>",
#     "active": "inactive"
# }
#
# On failure:
# {
#     "status": "fail",
#     "service": "<service_name>",
#     "message": "<error_message>"
# }
#
# - "service": The name of the service that was attempted to be stopped.
# - "active": The active status of the service after the stop attempt, which should be "inactive" on success.
# - "message": A message indicating the error if the stop command failed.
#
# Usage: ./script_name.sh <serviceName>
# Example: ./script_name.sh myService
#
# Exit codes:
# 0 - Success
# 1 - No service name provided
# 2 - Stop command failed

SERVICE_NAME="$1"

# Check if the service name was provided
if [ -z "$SERVICE_NAME" ]; then
    echo "{\"status\": \"fail\", \"message\": \"No service name provided. Usage: $0 <serviceName>\"}"
    exit 1
fi

# Attempt to stop the service
STOP_OUTPUT=$(systemctl --user stop "$SERVICE_NAME" 2>&1)

# Check if the stop command was successful
if [ $? -eq 0 ]; then
    ACTIVE_STATUS=$(systemctl --user is-active "$SERVICE_NAME" 2>&1)
    if [ "$ACTIVE_STATUS" = "inactive" ]; then
        echo "{\"status\": \"success\", \"service\": \"$SERVICE_NAME\", \"active\": \"$ACTIVE_STATUS\"}"
    else
        echo "{\"status\": \"fail\", \"service\": \"$SERVICE_NAME\", \"message\": \"Service is not inactive after stop attempt.\"}"
        exit 2
    fi
else
    echo "{\"status\": \"fail\", \"service\": \"$SERVICE_NAME\", \"message\": \"$STOP_OUTPUT\"}"
    exit 2
fi
