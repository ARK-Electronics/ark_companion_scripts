#!/bin/bash

# Directory containing user service files
SERVICE_DIR="$HOME/.config/systemd/user"

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

	# Print JSON object for the current service
	echo -n "{\"name\": \"${SERVICE_NAME}\", \"enabled\": \"${ENABLED_STATUS}\", \"active\": \"${ACTIVE_STATUS}\"}"

	# Add a comma after each service object except the last one
	if [ "$i" -lt "$((service_count - 1))" ]; then
		echo ","
	fi
done

# End JSON output
echo "]}"
