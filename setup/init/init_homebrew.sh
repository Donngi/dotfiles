#!/bin/sh

if ! command -v brew &> /dev/null
then
    echo "Install Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Start brew bundle..."
brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile"
