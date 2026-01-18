#!/bin/sh

echo "# ------------------------------------"
echo "# START: Deploy ghostty"
echo "# ------------------------------------"
echo ""

target="ghostty"
deploy_dir="$HOME/.config"
source_dir="$ZDOTDIR/.dotconfig/ghostty"

# Create backup directory
if [ ! -d "$deploy_dir/.dotbackup" ];then
    echo "$deploy_dir/.dotbackup not found. Automatically create it."
    mkdir -p "$deploy_dir/.dotbackup"
fi

backup_dir="$deploy_dir/.dotbackup/$(date +%Y%m%d-%H%M%S)"
echo "Create backup directory: $backup_dir"
echo ""
mkdir "$backup_dir"

# Backup existing ghostty config if exists
if [ -e "$deploy_dir/ghostty" ];then
    echo "$deploy_dir/ghostty already exists. Move the old dir to backup"
    mv "$deploy_dir/ghostty" "$backup_dir"
fi

# Create symbolic link
ln -s "$source_dir" "$deploy_dir"

echo ""
echo "# ------------------------------------"
echo "# DONE: Deploy ghostty"
echo "# ------------------------------------"
