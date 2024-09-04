#!/bin/bash
DEFAULT_XDG_CONF_HOME="$HOME/.config"
DEFAULT_XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DEFAULT_XDG_CONF_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$DEFAULT_XDG_DATA_HOME}"

sudo -v

function determine_target() {
	if [ -z "$TARGET" ]; then

		if uname -ar | grep tegra; then
			export TARGET=jetson
		else
			export TARGET=pi
		fi
	fi

	if [ -z "$TARGET_DIR" ]; then
		export TARGET_DIR="$PWD/platform/$TARGET"
	fi
}

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

function install_and_enable_target_service() {
	mkdir -p $XDG_CONFIG_HOME/systemd/user/
	cp $TARGET_DIR/services/$1.service $XDG_CONFIG_HOME/systemd/user/
	systemctl --user daemon-reload
	systemctl --user enable $1.service
	systemctl --user restart $1.service
}

function install_and_enable_service() {
	mkdir -p $XDG_CONFIG_HOME/systemd/user/
	cp $COMMON_DIR/services/$1.service $XDG_CONFIG_HOME/systemd/user/
	systemctl --user daemon-reload
	systemctl --user enable $1.service
	systemctl --user restart $1.service
}

function stop_disable_remove_service() {
	sudo systemctl stop $1.service &>/dev/null
	sudo systemctl disable $1.service &>/dev/null
	systemctl --user stop $1.service &>/dev/null
	systemctl --user disable $1.service &>/dev/null
	sudo rm /etc/systemd/system/$1.service &>/dev/null
	sudo rm /lib/systemd/system/$1.service &>/dev/null
	sudo rm $XDG_CONFIG_HOME/systemd/user/$1.service &>/dev/null
	sudo systemctl daemon-reload
	systemctl --user daemon-reload
}

function git_clone_retry() {
	local url="$1" dir="$2" branch="$3" retries=3 delay=5

	if [ -n "$branch" ]; then
		# Clone with a specific branch and avoid shallow clone
		until git clone --recurse-submodules -b "$branch" "$url" "$dir"; do
			((retries--)) || return 1
			echo "git clone failed, retrying in $delay seconds..."
			rm -rf "$dir" &>/dev/null
			sleep $delay
		done
	else
		# Shallow clone if no branch is specified
		until git clone --recurse-submodules --depth=1 --shallow-submodules "$url" "$dir"; do
			((retries--)) || return 1
			echo "git clone failed, retrying in $delay seconds..."
			rm -rf "$dir" &>/dev/null
			sleep $delay
		done
	fi
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