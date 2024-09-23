#!/bin/bash

APN="fast.t-mobile.com"

while true; do
		MODEM_LIST=$(mmcli -L | grep -Eo '/Modem/[0-9]+')
		if [ -n "$MODEM_LIST" ]; then
				# Extract the first modem instance (if multiple modems are found)
				MODEM_INSTANCE=$(echo "$MODEM_LIST" | head -n 1 | grep -Eo '[0-9]+')
				echo "Modem detected: instance $MODEM_INSTANCE"
				break
		else
				echo "No modem detected. Retrying in 5 seconds..."
				sleep 5
		fi
done

sudo mmcli -m $MODEM_INSTANCE --3gpp-set-initial-eps-bearer-settings="apn=$APN"
sudo mmcli -m $MODEM_INSTANCE --simple-connect="apn=$APN,ip-type=ipv4v6"

MODEM_STATE=$(mmcli -m $MODEM_INSTANCE --output-keyvalue | grep -E '^modem.generic.state[[:space:]]*:' | awk -F': ' '{print $2}')
if [ "$MODEM_STATE" != "connected" ]; then
	echo "Modem is not connected, exiting."
	exit 1
else
	echo "Modem is connected."
fi

BEARER_INFO=$(mmcli -m $MODEM_INSTANCE --bearer=1)

IP_ADDRESS=$(echo "$BEARER_INFO" | grep -Po '(?<=address: )[0-9.]+')
PREFIX=$(echo "$BEARER_INFO" | grep -Po '(?<=prefix: )[0-9]+')
GATEWAY=$(echo "$BEARER_INFO" | grep -Po '(?<=gateway: )[0-9.]+')
MTU=$(echo "$BEARER_INFO" | grep -Po '(?<=mtu: )[0-9]+')

echo "IP Address: $IP_ADDRESS"
echo "Prefix: $PREFIX"
echo "Gateway: $GATEWAY"
echo "MTU: $MTU"

sudo ip link set wwan0 up
sudo ip addr add $IP_ADDRESS/$PREFIX dev wwan0
sudo ip link set dev wwan0 arp off
sudo ip link set wwan0 mtu $MTU
sudo ip route add default via $GATEWAY dev wwan0 metric 4294967295

echo "ARK LTE modem setup completed."
