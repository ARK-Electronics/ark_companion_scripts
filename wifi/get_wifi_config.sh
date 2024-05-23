#!/bin/bash

# Source the environment variables
source /etc/profile.d/ark_env.sh

get_connection_details() {
  local ssid=$1
  local details
  details=$(nmcli -t -f 802-11-wireless.ssid,802-11-wireless-security.psk connection show "$ssid" -s 2>/dev/null || echo "")

  if [[ -z "$details" ]]; then
    echo "{\"ssid\": \"\", \"password\": \"\"}"
  else
    local ssid_value
    local password_value
    ssid_value=$(echo "$details" | grep "802-11-wireless.ssid" | cut -d ':' -f 2)
    password_value=$(echo "$details" | grep "802-11-wireless-security.psk" | cut -d ':' -f 2)
    echo "{\"ssid\": \"$ssid_value\", \"password\": \"$password_value\"}"
  fi
}

get_connection_status() {
  local ssid=$1
  if nmcli -t -f ACTIVE,SSID dev wifi | grep -q "yes:$ssid"; then
    echo "Connected"
  else
    echo "Disconnected"
  fi
}

ap_config=$(get_connection_details "$WIFI_AP_SSID")
station_config=$(get_connection_details "$WIFI_STATION_SSID")

# Combine both configurations into a single JSON object
ap_ssid=$(echo "$ap_config" | jq -r '.ssid')
ap_password=$(echo "$ap_config" | jq -r '.password')
station_ssid=$(echo "$station_config" | jq -r '.ssid')
station_password=$(echo "$station_config" | jq -r '.password')

# Get connection status
ap_status=$(get_connection_status "$ap_ssid")
station_status=$(get_connection_status "$station_ssid")

echo "{\"apSsid\": \"$ap_ssid\", \"apPassword\": \"$ap_password\", \"apStatus\": \"$ap_status\", \"stationSsid\": \"$station_ssid\", \"stationPassword\": \"$station_password\", \"stationStatus\": \"$station_status\", \"wifiMode\": \"$WIFI_MODE\"}"