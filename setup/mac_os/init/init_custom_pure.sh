#!/bin/sh

echo "# ------------------------------------"
echo "# START: Install custom pure"
echo "# ------------------------------------"
echo ""

mkdir -p "$HOME/.zsh"
if [ -d "$HOME/.zsh/pure" ]; then
    echo "Already exists $HOME/.zsh/pure. Update repository with git pull"
    cd "$HOME/.zsh/pure"
    git pull
    echo "Done: git pull"
else
    echo "Not exists $HOME/.zsh/pure. git clone"
    git clone https://github.com/Donngi/pure.git "$HOME/.zsh/pure"
fi

