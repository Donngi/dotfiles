#!/bin/sh

script_dir=$(cd $(dirname $0); pwd)

target="IntelliJ IDEA"
deploy_dir="$HOME/Library/Application Support/JetBrains/IdeaIC2021.1/keymaps"
source_dir="$ZDOTDIR/.dotconfig/idea"
files=("macOS_Jimon.xml")
source "$script_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
