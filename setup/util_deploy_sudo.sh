#!/bin/sh

# Usage:
# source ./util_deploy.sh <target> <deploy_dir> <files>
# - target     : string, target software name
# - deploy_dir : string, path of directry where to place symbolic links
# - source_dir : string, path of directry which contains files to link
# - files      : array of string, files to link. like 'file1 file2 file3'

target="$1"
deploy_dir="$2"
source_dir="$3"
files="$4"

echo "# ------------------------------------"
echo "# START: Deploy $target"
echo "# ------------------------------------"
echo ""

echo "[INFO] target application: $target"
echo "[INFO] deploy directory  : $deploy_dir"
echo "[INFO] source directory  : $source_dir"
echo "[INFO] files to link     : $files"
echo ""

# Create backup directory
if [ ! -d "$deploy_dir/.dotbackup" ];then
    echo "$deploy_dir/.dotbackup not found. Automatically create it."
    sudo mkdir -p "$deploy_dir/.dotbackup"
fi

backup_dir="$deploy_dir/.dotbackup/$(date +%Y%m%d-%H%M%S)"
echo "Create backup directory: $backup_dir"
echo ""
sudo mkdir "$backup_dir"

# Link target config files
file_length=`echo $files | tr ' ' '\n' | wc -l`
for i in `seq $file_length`
do
    f=`echo $files | cut -d ' ' -f $i`
    echo "Start to link $f"

    if [ -e "$deploy_dir/$f" ];then
        echo "$f already exists. Move the old file to backup"
        sudo mv "$deploy_dir/$f" "$backup_dir"
    fi

    sudo ln -sfnv "$source_dir/$f" "$deploy_dir"
    echo ""
done
