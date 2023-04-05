-- Select a file with telescope and also open it in nvim-tree
-- https://vi.stackexchange.com/questions/39274/highlight-nvim-tree-directory-that-contains-file-i-found-with-telescope
local transform_mod = require('telescope.actions.mt').transform_mod
local actions = require('telescope.actions')
local mod = {}
mod.open_in_nvim_tree = function(prompt_bufnr)
    local cur_win = vim.api.nvim_get_current_win()
    vim.cmd("NvimTreeFindFile")
    vim.api.nvim_set_current_win(cur_win)
end

mod = transform_mod(mod)

require("telescope").setup{
    defaults = {
        mappings = {
            i = {
                ["<CR>"] = actions.select_default + mod.open_in_nvim_tree,
            },
            n = {
                ["<CR>"] = actions.select_default + mod.open_in_nvim_tree,
            },
        },
    },
}