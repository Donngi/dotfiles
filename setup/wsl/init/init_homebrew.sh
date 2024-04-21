#!/bin/sh

echo "# ------------------------------------"
echo "# START: Install homebrew"
echo "# ------------------------------------"
echo ""

if ! command -v brew &> /dev/null
then
    echo "Install Homebrew ..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # 初回セットアップ時(zshにデフォルトシェルを切り替える前)に
    # homebrewでinstallしたコマンドを利用するケースがあるため、
    # .bashrcでもhomebrewのPATHを通しておく
    echo "Write homebrew path to .bashrc"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo ""
else
    echo "Homebrew is already installed."
    echo ""
fi

echo "Start brew bundle ..."
brew bundle --file "$HOME/.dotconfig/homebrew/wsl/Brewfile_dev_cli"
