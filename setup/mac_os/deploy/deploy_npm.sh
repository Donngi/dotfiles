#!/bin/bash

script_dir=$(
	cd "$(dirname "$0")" || exit
	pwd
)
os_dir=$(dirname "$script_dir")
setup_dir=$(dirname "$os_dir")

target="npm"
deploy_dir="$HOME"
source_dir="$ZDOTDIR/.dotconfig/npm"
files=".npmrc"
# shellcheck source=../../util_deploy.sh
source "$setup_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
