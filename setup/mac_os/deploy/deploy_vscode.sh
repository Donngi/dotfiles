#!/bin/sh

script_dir=$(cd $(dirname $0); pwd)
os_dir=$(dirname $script_dir);
setup_dir=$(dirname $os_dir);

target="VSCode"
deploy_dir="$HOME/Library/Application Support/Code/User"
source_dir="$ZDOTDIR/.dotconfig/vscode/mac_os"
files="keybindings.json"
source "$setup_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
