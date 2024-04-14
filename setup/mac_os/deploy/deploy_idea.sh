#!/bin/sh

script_dir=$(cd $(dirname $0); pwd)
os_dir=$(dirname $script_dir);
setup_dir=$(dirname $os_dir);

target="IntelliJ IDEA"
idea_version=$(ls "$HOME/Library/Application Support/JetBrains/" | grep IdeaIC)
deploy_dir="$HOME/Library/Application Support/JetBrains/${idea_version}/keymaps"
source_dir="$ZDOTDIR/.dotconfig/idea"
files="macOS_Donngi.xml"
source "$setup_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
