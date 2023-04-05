#!/bin/sh

echo "# ------------------------------------"
echo "# START: Deploy nvim"
echo "# ------------------------------------"
echo ""

script_dir=$(cd $(dirname $0); pwd)

target="neovim"
deploy_dir="$HOME/.config"
source_dir="$ZDOTDIR/.dotconfig/nvim"

# Create backup directory
if [ ! -d "$deploy_dir/.dotbackup" ];then
    echo "$deploy_dir/.dotbackup not found. Automatically create it."
    mkdir -p "$deploy_dir/.dotbackup"
fi

backup_dir="$deploy_dir/.dotbackup/$(date +%Y%m%d-%H%M%S)"
echo "Create backup directory: $backup_dir"
echo ""
mkdir "$backup_dir"

if [ -e "$deploy_dir/nvim" ];then
    echo "$HOME/.config/nvim already exists. Move the old dir to backup"
    mv "$deploy_dir/nvim" "$backup_dir"
fi

ln -s "$source_dir" "$deploy_dir"
