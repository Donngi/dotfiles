#!/bin/sh

script_dir=$(cd $(dirname $0); pwd)
os_dir=$(dirname $script_dir);
setup_dir=$(dirname $os_dir);

target="npm"
deploy_dir="$HOME"
source_dir="$ZDOTDIR/.dotconfig/npm"
files=".npmrc"
source "$setup_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
