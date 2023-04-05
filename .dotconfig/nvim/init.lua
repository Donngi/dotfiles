require("base")
require("plugins")
require("keymaps")
require("plugin_nvim_tree")
require("plugin_nvim_vscode")
require("plugin_telescope")

vim.cmd("autocmd BufWritePost plugins.lua PackerCompile") -- Auto compile when there are changes in plugins.lua
