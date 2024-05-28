#!/bin/bash

# Function to create and start a new connection
create_connection() {
	echo "No existing connection found with SSID $1. Creating and starting a new connection..."
	nmcli con add type wifi ifname wlo1 con-name "$1" autoconnect yes ssid "$1"
	nmcli con modify "$1" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$2"
}

# Check command line arguments
if [ "$#" -ne 2 ]; then
	echo "Usage: $0 SSID Password"
	exit 1
fi

SSID="$1"
PASSWORD="$2"

# Check if the connection with the given SSID already exists
if ! nmcli con show "$SSID" &>/dev/null; then
	create_connection "$SSID" "$PASSWORD"
fi

nmcli con up $SSID
# nmcli_pid=$!
# STATUS="fail"

# # Check every second up to 5 seconds if the process is still running
# for i in {1..5}; do
#     if ps -p $nmcli_pid > /dev/null; then
#         if [ $i -eq 5 ]; then
#             echo "Connection attempt taking too long, terminating..."
#             kill $nmcli_pid
#             echo "Connection failed" >&2
#             exit 1
#         fi
#         sleep 1
#     else
#         STATUS="success"
#         echo "Connected to WiFi"
#         exit 0
#     fi
# done

# echo "{\"status\": \"${STATUS}\", \"ssid\": \"${SSID}\", \"mode\": \"station\"}"
