#!/bin/bash

function ask_yes_no() {
	local prompt="$1"
	local var_name="$2"
	local default="$3"
	local default_display="${!var_name^^}"  # Convert to uppercase for display purposes

	while true; do
		echo "$prompt (y/n) [default: $default_display]"
		read -r REPLY
		if [ -z "$REPLY" ]; then
			REPLY="${!var_name}"
		fi
		case "$REPLY" in
			y|Y) eval $var_name="y"; break ;;
			n|N) eval $var_name="n"; break ;;
			*) echo "Invalid input. Please enter y or n." ;;
		esac
	done
}

function git_clone_retry() {
	local url="$1" dir="$2" retries=3 delay=5
	until git clone --recurse-submodules --depth=1 --shallow-submodules "$url" "$dir"; do
	((retries--)) || return 1
	echo "git clone failed, retrying in $delay seconds..."
	rm -rf "$dir" &>/dev/null
	sleep $delay
	done
}

function check_and_add_alias() {
	local name="$1"
	local command="$2"
	local file="$HOME/.bash_aliases"

	# Check if the alias file exists, create if not
	[ -f "$file" ] || touch "$file"

	# Check if the alias already exists
	if grep -q "^alias $name=" "$file"; then
		echo "Alias '$name' already exists."
	else
		# Add the new alias
		echo "alias $name='$command'" >> "$file"
		echo "Alias '$name' added."
	fi

	# Source the aliases file
	source "$file"
}

function sudo_refresh_loop() {
	while true; do
		sudo -v
		sleep 60
	done
}