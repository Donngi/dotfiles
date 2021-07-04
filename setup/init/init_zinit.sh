#!/bin/sh

echo "# ------------------------------------"
echo "# START: Install zinit"
echo "# ------------------------------------"
echo ""

if [ ! -d "$HOME/.zinit" ];then
    echo "$HOME/.zinit not found. Start to install zinit."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
else
    echo "zinit is already installed."
fi
