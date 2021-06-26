#!/bin/sh

VSCODE_DIR="$HOME/Library/Application Support/Code/User"

# Create backup directory
if [ ! -d "$VSCODE_DIR/.dotbackup" ];then
    echo "$VSCODE_DIR/.dotbackup not found. Automatically create it."
    mkdir "$VSCODE_DIR/.dotbackup"
fi

BACKUP_DIR=$VSCODE_DIR/.dotbackup/$(date +%Y%m%d-%H%M%S)
echo "Create backup directory: $BACKUP_DIR"
echo ""
mkdir $BACKUP_DIR

# Link vscode config files
files=("keybindings.json")
for f in $files
do
    echo "Start to link $f"

    if [ -e $VSCODE_DIR/$f ];then
        echo "$f already exists. Move the old file to backup"
        mv $VSCODE_DIR/$f $BACKUP_DIR
    fi

    ln -sfnv $HOME/.dotconfig/.vscode/$f $VSCODE_DIR
    echo ""
done
