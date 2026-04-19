#!/bin/bash

script_dir=$(
	cd "$(dirname "$0")" || exit
	pwd
)
os_dir=$(dirname "$script_dir")
setup_dir=$(dirname "$os_dir")

target="IntelliJ IDEA"
idea_dir=$(find "$HOME/Library/Application Support/JetBrains" -maxdepth 1 -name 'IdeaIC*' -print -quit 2>/dev/null)
if [ -z "$idea_dir" ]; then
	echo "[WARN] IntelliJ IDEA is not installed. Skipping deploy."
	exit 0
fi
idea_version=$(basename "$idea_dir")
deploy_dir="$HOME/Library/Application Support/JetBrains/${idea_version}/keymaps"
source_dir="$ZDOTDIR/.dotconfig/idea"
files="macOS_Donngi.xml"
# shellcheck source=../../util_deploy.sh
source "$setup_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
