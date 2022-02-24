#!/bin/sh

echo "# ------------------------------------"
echo "# START: Deploy home"
echo "# ------------------------------------"
echo ""

# Create backup directory
if [ ! -d "$HOME/.dotbackup" ];then
    echo "$HOME/.dotbackup not found. Automatically create it."
    mkdir "$HOME/.dotbackup"
fi

BACKUP_DIR=$HOME/.dotbackup/$(date +%Y%m%d-%H%M%S)
echo "Create backup directory: $BACKUP_DIR"
echo ""
mkdir $BACKUP_DIR

script_dir=$(cd $(dirname $0); pwd)
setup_dir=$(dirname $script_dir);
repository_dir=$(dirname $setup_dir);

# Link dotfiles to HOME directory
for file_path in "$repository_dir"/.??*
do
    f=$(echo $file_path | rev | cut -d '/' -f 1 | rev)

    if [ "$f" = ".git" ]; then
        continue
    fi
    if [ "$f" = ".DS_Store" ]; then
        continue
    fi
    if [ "$f" = ".gitignore" ]; then
        continue
    fi

    echo "Start to link $f"

    if [ -e $HOME/$f ];then
        echo "$f already exists. Move the old file to backup"
        mv $HOME/$f $BACKUP_DIR
    fi

    DOTFILES_PATH="$repository_dir"
    ln -sfnv $DOTFILES_PATH/$f $HOME
    echo ""
done
