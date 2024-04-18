#!/bin/sh

echo "This setup script is designed for FIRST SETUP ONLY."
echo "Do you want to continue? (y/N)"
read input

if [ "$input" != "Y" ] && [ "$input" != "y" ]; then
    echo "Command canceled."
    exit 0
fi

echo "# ------------------------------------"
echo "# START: All in one setup"
echo "# ------------------------------------"

# Apple silicon mac
if [[ `uname -m` == 'arm64' ]]; then 
    # macOSの場合、デフォルトでmakeが使えるため、makeコマンドを実行するのみ
    # (コマンド間の依存関係は、makefile内で吸収)
    make mac-os-all-in-one

# WSL
elif [[ `uname -a` == *"microsoft"* && `uname -s` == "Linux"* ]]; then 
    # wsl上のlinuxの場合、makeがインストールされていないため、
    # インストールしてからmakeコマンド実行
    source ./setup/wsl/init/init_ca_certificates.sh
    source ./setup/wsl/init/init_build_essential.sh
    make wsl-all-in-one
fi
