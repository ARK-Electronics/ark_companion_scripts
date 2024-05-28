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

AP_SSID=$(find_existing_ap)
AP_PASSWORD=""

if [ -n "$AP_SSID" ]; then
    AP_PASSWORD=$(nmcli -g 802-11-wireless-security.psk con show "$AP_SSID" -s)
fi

echo "{\"status\": \"Success\", \"message\": \"TODO\", \"ssid\": \"$AP_SSID\", \"password\": \"$AP_PASSWORD\"}"
