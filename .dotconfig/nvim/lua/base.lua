vim.g.shell = '/bin/zsh'

-- language
vim.api.nvim_exec('language en_US', true)

-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.shiftwidth=4 -- インデント幅
vim.opt.tabstop=4 -- スペースをタブに自動変換するしきい値

vim.opt.autoindent=true

vim.opt.clipboard="unnamed" -- vimのyankをclipboardに保存する

vim.opt.termguicolors = true
vim.opt.number=true
vim.opt.syntax="on"

vim.g.mapleader=" "
