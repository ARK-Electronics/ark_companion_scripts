#!/bin/bash

SERVICE_NAME="$1"

# Check if the service name was provided
if [ -z "$SERVICE_NAME" ]; then
    echo "{\"status\": \"fail\", \"message\": \"No service name provided. Usage: $0 <serviceName>\"}"
    exit 1
fi

# Fetch the last 50 lines of logs for the specified service
LOG_OUTPUT=$(journalctl --user -u "$SERVICE_NAME" -n 50 --no-pager 2>&1)

# Check if the command was successful
if [ $? -eq 0 ]; then
    # Escape newlines and quotes for JSON
    LOG_OUTPUT_ESCAPED=$(echo "$LOG_OUTPUT" | jq -Rs .)
    echo "{\"status\": \"success\", \"service\": \"$SERVICE_NAME\", \"logs\": $LOG_OUTPUT_ESCAPED}"
else
    echo "{\"status\": \"fail\", \"service\": \"$SERVICE_NAME\", \"message\": \"$LOG_OUTPUT\"}"
    exit 2
fi
