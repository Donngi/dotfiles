#!/bin/sh

echo "# ------------------------------------"
echo "# START: Set default shell zsh"
echo "# ------------------------------------"

zsh_path=$(which zsh)

if [ -z "$zsh_path" ]; then
    echo "zsh is not installed."
    exit 1
fi

# /etc/shellsにzshが登録されていない場合追記
if ! grep -q "$zsh_path" /etc/shells; then
    echo "zsh is not listed in /etc/shells, adding it now."
    echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to add zsh to /etc/shells."
        exit 1
    fi
fi

# デフォルトシェルをzshに変更
chsh -s "$zsh_path"
if [ $? -ne 0 ]; then
    echo "Failed to change default shell to zsh."
    exit 1
fi

echo "Default shell changed to zsh successfully."
