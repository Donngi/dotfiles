#!/bin/sh

echo "# ------------------------------------"
echo "# START: Install vim plugins"
echo "# ------------------------------------"
echo ""

# https://github.com/wbthomason/packer.nvim
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# https://github.com/tpope/vim-commentary
mkdir -p ~/.config/nvim/pack/tpope/start
cd ~/.config/nvim/pack/tpope/start
git clone https://tpope.io/vim/commentary.git
vim -u NONE -c "helptags commentary/doc" -c q

