#!/bin/sh

script_dir=$(cd $(dirname $0); pwd)

target="VSCode"
deploy_dir="$ZDOTDIR/Library/Application Support/Code/User"
source_dir="$ZDOTDIR/.dotconfig/vscode"
files=("keybindings.json")
source "$script_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
