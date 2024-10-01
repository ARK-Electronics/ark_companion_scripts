#!/bin/bash

SERVICE_NAME="$1"
CONFIG_CONTENT="$2"

# Base directory containing service data
BASE_DIR="$HOME/.local/share"

# Check if the service name and config content were provided
if [ -z "$SERVICE_NAME" ] || [ -z "$CONFIG_CONTENT" ]; then
	echo "{\"status\": \"fail\", \"data\": \"Usage: $0 <serviceName> <configContent>\"}"
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

		# Full path to the config file
		CONFIG_FILE="$dir/$CONFIG_FILE_NAME"

		# Check if the config file exists
		if [ -f "$CONFIG_FILE" ]; then
			# Save the new configuration content to the config file
			echo "$CONFIG_CONTENT" > "$CONFIG_FILE"
			if [ $? -eq 0 ]; then
				echo "{\"status\": \"success\", \"data\": \"Configuration saved successfully\"}"
				exit 0
			else
				echo "{\"status\": \"fail\", \"data\": \"Failed to save configuration\"}"
				exit 2
			fi
		else
			echo "{\"status\": \"fail\", \"data\": \"$CONFIG_FILE_NAME not found in $dir\"}"
			exit 2
		fi
	fi
done

# If the service directory was not found
if [ "$service_found" = false ]; then
	echo "{\"status\": \"fail\", \"data\": \"Service $SERVICE_NAME not found in $BASE_DIR\"}"
	exit 3
fi
