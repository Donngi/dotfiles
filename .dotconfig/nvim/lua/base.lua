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
vim.opt.scrolloff=6 -- カーソルが画面端から6行以内に入らないよう自動スクロール
vim.opt.autowriteall=true -- バッファ切替やフォーカス移動時に自動保存
vim.opt.autoread=true -- 外部でファイルが変更された場合に自動で再読み込み
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  command = "checktime",
})

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
vim.keymap.set('i', '<C-h>', '<BS>', { noremap = true, desc = '前の文字を削除' })
vim.keymap.set('i', '<C-d>', '<Del>', { noremap = true, desc = 'カーソル位置の文字を削除' })
vim.keymap.set('i', '<C-k>', '<C-o>D', { noremap = true, desc = 'カーソル位置から行末まで削除' })

-- ノーマルモードで15行ずつ移動
vim.keymap.set('n', '<C-j><C-k>', '15k', { noremap = true, desc = '15行上に移動' })
vim.keymap.set('n', '<C-j><C-j>', '15j', { noremap = true, desc = '15行下に移動' })

-- インサートモードでも15行ずつ移動
vim.keymap.set('i', '<C-j><C-k>', '<C-o>15k', { noremap = true, desc = '15行上に移動' })
vim.keymap.set('i', '<C-j><C-j>', '<C-o>15j', { noremap = true, desc = '15行下に移動' })

-- 検索ハイライトをクリア
vim.keymap.set('n', '<Esc><Esc>', ':nohlsearch<CR>', { noremap = true, silent = true, desc = '検索ハイライトをクリア' })

-- バッファ操作
vim.keymap.set('n', '<S-h>', ':bprevious<CR>', { noremap = true, silent = true, desc = '前のバッファ' })
vim.keymap.set('n', '<S-l>', ':bnext<CR>', { noremap = true, silent = true, desc = '次のバッファ' })
vim.keymap.set('n', '<leader>bd', ':bdelete<CR>', { noremap = true, silent = true, desc = 'バッファを閉じる' })
