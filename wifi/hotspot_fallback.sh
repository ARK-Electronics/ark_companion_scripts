#!/bin/bash

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

# sleep for 30 seconds
# If NM isn't connected start the hotspot
sleep 30

wifi_connected=$(nmcli con show --active | grep wifi)
if [ -n "$wifi_connected" ]; then
	echo "WiFi is connected, not setting up hotspot"
	exit 0
fi

AP_SSID=$(find_existing_ap)

if [ -n "$AP_SSID" ]; then
	# Access point exists, start it
	nmcli con up $AP_SSID
 else
 	echo "Creating new hotspot"
	# Create default hotspot
	AP_SSID="ARK_Hotspot"
	AP_PASSWORD="password"
	nmcli con add type wifi ifname '*' con-name $AP_SSID autoconnect no ssid $AP_SSID 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
	nmcli con modify $AP_SSID wifi-sec.key-mgmt wpa-psk wifi-sec.psk $AP_PASSWORD 802-11-wireless-security.pmf disable
	nmcli con up $AP_SSID
fi

echo "Starting hotspot: $AP_SSID"
