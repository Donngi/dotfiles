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

-- Markdownファイルで箇条書きの自動挿入を有効化
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.formatoptions:append("r")  -- Enterで自動的に箇条書きを継続
    vim.opt_local.comments = "b:-,b:*"       -- - と * を箇条書き記号として認識
  end,
})

-- インサートモードでmacOS標準のEmacs風キーバインドを有効化
vim.keymap.set('i', '<C-f>', '<Right>', { noremap = true, desc = '右に移動' })
vim.keymap.set('i', '<C-b>', '<Left>', { noremap = true, desc = '左に移動' })
vim.keymap.set('i', '<C-p>', '<Up>', { noremap = true, desc = '上に移動' })
vim.keymap.set('i', '<C-n>', '<Down>', { noremap = true, desc = '下に移動' })
vim.keymap.set('i', '<C-a>', '<Home>', { noremap = true, desc = '行頭に移動' })
vim.keymap.set('i', '<C-e>', '<End>', { noremap = true, desc = '行末に移動' })
vim.keymap.set('i', '<C-k>', '<C-o>D', { noremap = true, desc = 'カーソル位置から行末まで削除' })
