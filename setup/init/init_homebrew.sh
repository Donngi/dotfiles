#!/bin/sh

echo "# ------------------------------------"
echo "# START: Install homebrew"
echo "# ------------------------------------"
echo ""

if ! command -v brew &> /dev/null
then
    echo "Install Homebrew ..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo ""
else
    echo "Homebrew is already installed."
    echo ""
fi

echo "Start brew bundle ..."
brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile"
