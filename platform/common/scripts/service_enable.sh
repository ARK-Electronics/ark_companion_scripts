#!/bin/bash

# This script attempts to enable a specified user service and outputs a JSON structure with the result.
#
# The JSON structure is as follows:
#
# On success:
# {
#     "status": "success",
#     "service": "<service_name>",
#     "enabled": "enabled"
# }
#
# On failure:
# {
#     "status": "fail",
#     "service": "<service_name>",
#     "message": "<error_message>"
# }
#
# - "service": The name of the service that was attempted to be enabled.
# - "enabled": The enabled status of the service after the enable attempt, which should be "enabled" on success.
# - "message": A message indicating the error if the enable command failed.
#
# Usage: ./script_name.sh <serviceName>
# Example: ./script_name.sh myService
#
# Exit codes:
# 0 - Success
# 1 - No service name provided
# 2 - Enable command failed

SERVICE_NAME="$1"

# Check if the service name was provided
if [ -z "$SERVICE_NAME" ]; then
    echo "{\"status\": \"fail\", \"message\": \"No service name provided. Usage: $0 <serviceName>\"}"
    exit 1
fi

# Attempt to enable the service
ENABLE_OUTPUT=$(systemctl --user enable "$SERVICE_NAME" 2>&1)

# Check if the enable command was successful
if [ $? -eq 0 ]; then
    echo "{\"status\": \"success\", \"service\": \"$SERVICE_NAME\", \"enabled\": \"enabled\"}"
else
    echo "{\"status\": \"fail\", \"service\": \"$SERVICE_NAME\", \"message\": \"$ENABLE_OUTPUT\"}"
    exit 2
fi
