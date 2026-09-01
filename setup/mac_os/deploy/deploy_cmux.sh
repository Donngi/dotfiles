#!/bin/bash

script_dir=$(
	cd "$(dirname "$0")" || exit
	pwd
)
os_dir=$(dirname "$script_dir")
setup_dir=$(dirname "$os_dir")

target="cmux"
deploy_dir="$HOME/.config/cmux"
source_dir="$ZDOTDIR/.dotconfig/cmux"
files="cmux.json"
# shellcheck source=../../util_deploy.sh
source "$setup_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
