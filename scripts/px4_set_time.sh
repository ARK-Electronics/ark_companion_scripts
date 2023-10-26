#!/bin/bash
HOST_IP=127.0.0.1
HOST_PORT=14551

UNIX_EPOCH_TIME=$(date +%s) # %s = seconds since the Epoch (1970-01-01 00:00 UTC)
output=$(python3 /usr/bin/px4_shell_command.py -p "udp:$HOST_IP:$HOST_PORT" "system_time set $UNIX_EPOCH_TIME")

if [ -z $output ]; then
	echo "Setting time failed!"
	echo "output: $output"
	exit 1
fi

echo "Setting time succeed!"
echo "output: $output"
