#!/bin/sh

echo "# ------------------------------------"
echo "# START: Install ZI"
echo "# ------------------------------------"
echo ""

if [ ! -d "$HOME/.zi" ];then
    echo "$HOME/.zi not found. Start to install zi."
    sh -c "$(curl -fsSL git.io/get-zi)" -- -i skip -b main
else
    echo "zi is already installed."
fi
