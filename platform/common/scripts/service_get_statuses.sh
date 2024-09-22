#!/bin/bash

# This script outputs a JSON structure that lists all user services along with their enabled status, active status,
# and the config file name if available. If no config file is available, it returns an empty string.
#
# The JSON structure is as follows:
# {
#     "services": [
#         {
#             "name": "<service_name>",
#             "enabled": "<enabled_status>",
#             "active": "<active_status>",
#             "config_file": "<config_file_name_or_empty_string>",
#             "visible": "<true|false>"
#         },
#         ...
#     ]
# }
#
# - "name": The name of the service (without the .service extension).
# - "enabled": The enabled status of the service ("enabled", "disabled", or an error message).
# - "active": The active status of the service ("active", "inactive", or an error message).
# - "config_file": The name of the config file if available, or an empty string if not.
# - "visible": Indicates whether the service should be visible in the UI ("true" or "false").
#
# Example usage: ./service_get_statuses.sh
# This script does not take any arguments.
#
# Exit codes:
# 0 - Success

SERVICE_DIR="$HOME/.config/systemd/user"
BASE_DIR="$HOME/.local/share"

echo "{\"services\": ["

service_files=("$SERVICE_DIR"/*.service)
service_count=${#service_files[@]}

for i in "${!service_files[@]}"; do
	SERVICE_NAME=$(basename "${service_files[$i]}" .service)
	ENABLED_STATUS=$(systemctl --user is-enabled "$SERVICE_NAME" 2>&1)
	ACTIVE_STATUS=$(systemctl --user is-active "$SERVICE_NAME" 2>&1)

	MANIFEST_FILE="$BASE_DIR/$SERVICE_NAME/$SERVICE_NAME.manifest.json"
	VISIBLE="true"
	CONFIG_FILE_NAME=""

	if [ -f "$MANIFEST_FILE" ]; then
		VISIBLE=$(grep -Po '(?<="visible": )[^,]*' "$MANIFEST_FILE" | tr -d ' ')
		[ -z "$VISIBLE" ] && VISIBLE="true"

		CONFIG_FILE_NAME=$(grep -Po '(?<="configFile": ")[^"]*' "$MANIFEST_FILE")
	fi

	CONFIG_FILE="$BASE_DIR/$SERVICE_NAME/$CONFIG_FILE_NAME"
	if [ ! -f "$CONFIG_FILE" ]; then
		CONFIG_FILE_NAME=""
	fi

	echo -n "{\"name\": \"${SERVICE_NAME}\", \"enabled\": \"${ENABLED_STATUS}\", \"active\": \"${ACTIVE_STATUS}\", \"config_file\": \"${CONFIG_FILE_NAME}\", \"visible\": \"${VISIBLE}\"}"

	if [ "$i" -lt "$((service_count - 1))" ]; then
		echo ","
	fi
done

echo "]}"
