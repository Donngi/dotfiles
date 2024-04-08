#!/bin/sh

script_dir=$(cd $(dirname $0); pwd)

target="VSCode"
deploy_dir="$HOME/Library/Application Support/Code/User"
source_dir="$ZDOTDIR/.dotconfig/vscode/mac_os"
files="keybindings.json"
source "$script_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
