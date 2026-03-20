#!/bin/sh

script_dir=$(cd $(dirname $0); pwd)
os_dir=$(dirname $script_dir);
setup_dir=$(dirname $os_dir);

target="Claude Code"
deploy_dir="$HOME/.claude"
source_dir="$ZDOTDIR/.dotconfig/claude"
files="statusline-command.sh"
source "$setup_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
