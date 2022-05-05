#!/bin/sh

echo "# ------------------------------------"
echo "# START: Install ZI"
echo "# ------------------------------------"
echo ""

if [ ! -d "$HOME/.zi" ];then
    echo "$HOME/.zi not found. Start to install zi."
    sh -c "$(curl -fsSL https://zsh.pages.dev/i)" --
else
    echo "zi is already installed."
fi
