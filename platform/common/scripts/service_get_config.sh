#!/bin/bash

# This script outputs JSON structures in the following format:
#
# On success:
# {
#     "status": "success",
#     "data": "<contents of config.toml in JSON string format>"
# }
#
# On failure:
# {
#     "status": "fail",
#     "data": "<error message>"
# }
#
# Usage: ./script_name.sh <serviceName>
# Example: ./script_name.sh myService
#
# Exit codes:
# 1 - Service name not provided
# 2 - config.toml not found in the service directory
# 3 - Service directory not found

SERVICE_NAME="$1"

# Base directory containing service data
BASE_DIR="$HOME/.local/share"

# Check if the service name was provided
if [ -z "$SERVICE_NAME" ]; then
	echo -e "{\"status\": \"fail\", \"data\": \"Usage: $0 <serviceName>\"}"
	exit 1
fi

# Initialize flag for finding the service directory
service_found=false

# Loop through all directories in the base directory
for dir in "$BASE_DIR"/*/; do
	# Extract the directory name
	dir_name=$(basename "$dir")

	# Check if the directory name matches the service name
	if [ "$dir_name" == "$SERVICE_NAME" ]; then
		service_found=true

		# Default config file name
		CONFIG_FILE_NAME="config.toml"

		# Check if a manifest file exists and read the configFile entry
		MANIFEST_FILE="$dir/$SERVICE_NAME.manifest.json"
		if [ -f "$MANIFEST_FILE" ]; then
			CONFIG_FILE_NAME=$(grep -Po '(?<="configFile": ")[^"]*' "$MANIFEST_FILE")
			[ -z "$CONFIG_FILE_NAME" ] && CONFIG_FILE_NAME="config.toml"  # Fallback to default if empty
		fi

		# Check if the config file exists in the directory
		CONFIG_FILE="$dir/$CONFIG_FILE_NAME"
		if [ -f "$CONFIG_FILE" ]; then
			# Output the contents of the config file in JSON format
			config_content=$(cat "$CONFIG_FILE" | jq -Rs .)
			echo "{\"status\": \"success\", \"data\": ${config_content}}"
			exit 0
		else
			echo "{\"status\": \"fail\", \"data\": \"$CONFIG_FILE_NAME not found in $dir\"}"
			exit 2
		fi
	fi
done

# If the service directory was not found
if [ "$service_found" = false ]; then
	echo -e "{\"status\": \"fail\", \"data\": \"Service $SERVICE_NAME not found in $BASE_DIR\"}"
	exit 3
fi
