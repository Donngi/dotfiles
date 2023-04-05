require("base")
require("plugins")
require("keymaps")
require("nvim_tree")
require("nvim_vscode")

vim.cmd("autocmd BufWritePost plugins.lua PackerCompile") -- Auto compile when there are changes in plugins.lua
