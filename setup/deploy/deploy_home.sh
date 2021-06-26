#!/bin/sh

# Create backup directory
if [ ! -d "$HOME/.dotbackup" ];then
    echo "$HOME/.dotbackup not found. Automatically create it."
    mkdir "$HOME/.dotbackup"
fi

BACKUP_DIR=$HOME/.dotbackup/$(date +%Y%m%d-%H%M%S)
echo "Create backup directory: $BACKUP_DIR"
echo ""
mkdir $BACKUP_DIR

# Link dotfiles to HOME directory
for f in .??*
do
    [[ "$f" == ".git" ]] && continue
    [[ "$f" == ".DS_Store" ]] && continue
    [[ "$f" == ".gitignore" ]] && continue

    echo "Start to link $f"

    if [ -e $HOME/$f ];then
        echo "$f already exists. Move the old file to backup"
        mv $HOME/$f $BACKUP_DIR
    fi

    # TODO: dotfilesのroot directoryの取得方法を精査する
    DOTFILES_PATH=$(pwd)
    ln -sfnv $DOTFILES_PATH/$f $HOME
    echo ""
done
