#!/bin/sh

echo "# ------------------------------------"
echo "# START: Install homebrew"
echo "# ------------------------------------"
echo ""

if ! command -v brew &> /dev/null
then
    echo "Install Homebrew ..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # deploy完了までの間にhomebrewのpathを通すため、一時的に.zprofileにpathを書き込む(deploy phaseで上書きされる)
    echo "Write homebrew path to .zprofile"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
    source $HOME/.zprofile
    echo ""
else
    echo "Homebrew is already installed."
    echo ""
fi

echo "Start brew bundle ..."
brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile_homebrew"
brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile_dev_cli"
brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile_dev_gui"
brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile_applications"
