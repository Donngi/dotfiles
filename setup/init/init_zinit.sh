#!/bin/sh

if [ ! -d "$HOME/.zinit" ];then
    echo "$HOME/.zinit not found. Start to install zinit."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
fi
