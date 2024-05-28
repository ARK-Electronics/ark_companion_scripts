#!/bin/bash

# Function to start the connection
start_ap() {
  echo "Starting the access point: $1"
  nmcli con up "$1"
}

# Function to modify an existing AP connection
update_ap_password() {
	echo "Updating password: $1"
	nmcli con modify "$1" wifi-sec.psk "$2"
	nmcli con up "$1"
}

# Function to delete and create a new AP connection
replace_ap() {
	echo "Replacing $1 with $2"
	nmcli con delete "$1"
	create_ap "$2" "$3"
}

# Function to create a new AP connection
create_ap() {
	echo "Creating and starting a new access point: $1"
	nmcli con add type wifi ifname wlo1 con-name "$1" autoconnect no ssid "$1" 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
	nmcli con modify "$1" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$2" 802-11-wireless-security.pmf disable
	nmcli con up "$1"
}

# Function to find an existing AP
find_existing_ap() {
	local connections=$(nmcli -t -f NAME,TYPE con show | grep "802-11-wireless" | cut -d ':' -f1)
	for connection in $connections; do
		local mode=$(nmcli -t -f 802-11-wireless.mode con show "$connection")
		if [[ $mode == "802-11-wireless.mode:ap" ]]; then
			echo "$connection"
			return
		fi
	done
	echo ""
}

# Check command line arguments
if [ "$#" -ne 2 ]; then
	# echo "Usage: $0 <ssid> <password>"
	echo "{\"status\": \"fail\", \"mode\": \"ap\"}"
	exit 1
fi

SSID="$1"
PASSWORD="$2"

# Check for an existing AP
existing_ap=$(find_existing_ap)

# Manage the AP connection
if [ -n "$existing_ap" ]; then
	if [ "$SSID" == "$existing_ap" ]; then
		current_password=$(nmcli -g 802-11-wireless-security.psk con show "$existing_ap" -s)
		if [ "$PASSWORD" == "$current_password" ]; then
			start_ap "$existing_ap"
		else
			update_ap_password "$existing_ap" "$PASSWORD"
		fi
	else
		replace_ap "$existing_ap" "$SSID" "$PASSWORD"
	fi
else
	create_ap "$SSID" "$PASSWORD"
fi

echo "Operation completed."
echo "{\"status\": \"success\", \"ssid\": \"${SSID}\", \"mode\": \"ap\"}"
