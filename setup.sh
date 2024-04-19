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
    make mac-os-deploy-home
    make mac-os-init-brew
    make mac-os-init-all
    make mac-os-deploy-all

    echo "### Setup success! ###"

# WSL
elif [[ `uname -a` == *"microsoft"* && `uname -s` == "Linux"* ]]; then 
    # wsl上のlinuxの場合、makeがインストールされていないため、
    # インストールしてからmakeコマンド実行
    source ./setup/wsl/init/init_ca_certificates.sh
    source ./setup/wsl/init/init_build_essential.sh
    make wsl-deploy-home
    make wsl-init-brew
    make wsl-init-all
    make wsl-deploy-all
    echo "### Setup success! ###"
fi
