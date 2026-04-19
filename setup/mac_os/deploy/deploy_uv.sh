#!/bin/bash

target="uv"
deploy_dir="$HOME/.config/uv"
source_dir="$ZDOTDIR/.dotconfig/uv"

echo "# ------------------------------------"
echo "# START: Deploy $target"
echo "# ------------------------------------"
echo ""

# Create deploy directory if not exists
if [ ! -d "$deploy_dir" ]; then
	echo "$deploy_dir not found. Automatically create it."
	mkdir -p "$deploy_dir"
fi

# Create backup directory
if [ ! -d "$deploy_dir/.dotbackup" ]; then
	echo "$deploy_dir/.dotbackup not found. Automatically create it."
	mkdir -p "$deploy_dir/.dotbackup"
fi

backup_dir="$deploy_dir/.dotbackup/$(date +%Y%m%d-%H%M%S)"
echo "Create backup directory: $backup_dir"
echo ""
mkdir "$backup_dir"

# Backup existing uv.toml if exists
if [ -e "$deploy_dir/uv.toml" ]; then
	echo "$deploy_dir/uv.toml already exists. Move the old file to backup"
	mv "$deploy_dir/uv.toml" "$backup_dir"
fi

# Create symbolic link
ln -sfnv "$source_dir/uv.toml" "$deploy_dir"

echo ""
echo "# ------------------------------------"
echo "# DONE: Deploy $target"
echo "# ------------------------------------"
