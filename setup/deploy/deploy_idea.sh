#!/bin/sh

IDEA_DIR="$HOME/Library/Application Support/Code/User"

# Create backup directory
if [ ! -d "$IDEA_DIR/.dotbackup" ];then
    echo "$IDEA_DIR/.dotbackup not found. Automatically create it."
    mkdir "$IDEA_DIR/.dotbackup"
fi

BACKUP_DIR=$IDEA_DIR/.dotbackup/$(date +%Y%m%d-%H%M%S)
echo "Create backup directory: $BACKUP_DIR"
echo ""
mkdir $BACKUP_DIR

# Link vscode config files
files=("macOS_Jimon.xml")
for f in $files
do
    echo "Start to link $f"

    if [ -e $IDEA_DIR/$f ];then
        echo "$f already exists. Move the old file to backup"
        mv $IDEA_DIR/$f $BACKUP_DIR
    fi

    ln -sfnv $HOME/.dotconfig/idea/$f $IDEA_DIR
    echo ""
done
