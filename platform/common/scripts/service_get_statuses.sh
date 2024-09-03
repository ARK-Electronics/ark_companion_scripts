#!/bin/bash

# This script outputs a JSON structure that lists all user services along with their enabled status, active status,
# and whether a config.toml file is present.
#
# The JSON structure is as follows:
# {
#     "services": [
#         {
#             "name": "<service_name>",
#             "enabled": "<enabled_status>",
#             "active": "<active_status>",
#             "config_present": "<true|false>"
#         },
#         ...
#     ]
# }
#
# - "name": The name of the service (without the .service extension).
# - "enabled": The enabled status of the service ("enabled", "disabled", or an error message).
# - "active": The active status of the service ("active", "inactive", or an error message).
# - "config_present": Indicates whether a config.toml file is present ("true" or "false").
#
# Example usage: ./script_name.sh
# This script does not take any arguments.
#
# Exit codes:
# 0 - Success

# Directory containing user service files
SERVICE_DIR="$HOME/.config/systemd/user"
# Base directory where service configurations might be located
BASE_DIR="$HOME/.local/share"

# Start JSON output
echo "{\"services\": ["


# Get the list of service files
service_files=("$SERVICE_DIR"/*.service)
service_count=${#service_files[@]}

# Loop through all service files in the directory
for i in "${!service_files[@]}"; do
	# Extract the service name from the path
	SERVICE_NAME=$(basename "${service_files[$i]}" .service)

	# Get the status of the service
	ENABLED_STATUS=$(systemctl --user is-enabled "$SERVICE_NAME" 2>&1)
	ACTIVE_STATUS=$(systemctl --user is-active "$SERVICE_NAME" 2>&1)

	# Check if the config.toml file exists for this service
	CONFIG_FILE="$BASE_DIR/$SERVICE_NAME/config.toml"
	if [ -f "$CONFIG_FILE" ]; then
		CONFIG_AVAILABLE="true"
	else
		CONFIG_AVAILABLE="false"
	fi

	# Print JSON object for the current service
	echo -n "{\"name\": \"${SERVICE_NAME}\", \"enabled\": \"${ENABLED_STATUS}\", \"active\": \"${ACTIVE_STATUS}\", \"config_available\": \"${CONFIG_AVAILABLE}\"}"

	# Add a comma after each service object except the last one
	if [ "$i" -lt "$((service_count - 1))" ]; then
		echo ","
	fi
done

# End JSON output
echo "]}"
