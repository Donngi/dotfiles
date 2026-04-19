#!/bin/bash

script_dir=$(
	cd "$(dirname "$0")" || exit
	pwd
)
os_dir=$(dirname "$script_dir")
setup_dir=$(dirname "$os_dir")

target="WSL conf"
deploy_dir="/etc"
source_dir="$ZDOTDIR/.dotconfig/wsl"
files="wsl.conf"
# shellcheck source=../../util_deploy_sudo.sh
source "$setup_dir/util_deploy_sudo.sh" "$target" "$deploy_dir" "$source_dir" "$files"
