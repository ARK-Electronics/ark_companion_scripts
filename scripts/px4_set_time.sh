#!/bin/bash
HOST_IP=127.0.0.1
HOST_PORT=14569

UNIX_EPOCH_TIME=$(date +%s) # %s = seconds since the Epoch (1970-01-01 00:00 UTC)
output=$(python3 /usr/bin/px4_shell_command.py -p "udp:$HOST_IP:$HOST_PORT" "system_time set $UNIX_EPOCH_TIME")

if [[ $output != *"Successfully set system time"* ]]; then
	echo "Failed to set system time!"
	echo "response: $output"
	exit 1
fi

echo "Successfully set system time"
echo "response: $output"

# never exit, hack to allow restarting w/ mavlink-router
tail -f

# journalctl -b -f \
#     -u systemd-timesyncd.service \
#     -u systemd-time-wait-sync.service \
#     -u time-sync.target \
#     -u mavlink-router.service \
#     -u px4-time.service
