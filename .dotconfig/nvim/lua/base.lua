vim.g.shell = '/bin/zsh'

-- locale/encoding (avoid mojibake on non-ASCII yanks)
vim.env.LANG = "en_US.UTF-8"
vim.env.LC_ALL = "en_US.UTF-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = { "utf-8", "ucs-bom", "latin1" }

-- language
vim.api.nvim_exec('language en_US.UTF-8', true)

-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.shiftwidth=4 -- インデント幅
vim.opt.tabstop=4 -- スペースをタブに自動変換するしきい値

vim.opt.autoindent=true

-- クリップボード連携
-- 背景: vim.opt.clipboard="unnamed"やunnamedplusを使った方法では、
--       pbpasteを経由して日本語が文字化けする問題があった。
-- 解決: neovim内部レジスタでyank/pasteを行い、yankした内容は自動的に
--       pbcopyでシステムクリップボードにも送信する。
-- 動作:
--   - yank時: neovim内部レジスタに保存し、autocmdで自動的にpbcopyで
--             システムクリップボードにも送信(日本語も正常に動作)
--   - paste(p): neovim内部レジスタから貼り付け(日本語の文字化けなし)
--   - システムクリップボードから貼り付け: <leader>v で可能

-- clipboard optionは設定しない(neovim内部レジスタを使用)

-- yankした内容を自動的にpbcopyでシステムクリップボードに送信
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    if vim.v.event.operator ~= 'y' then
      return
    end
    local content = vim.v.event.regcontents
    if not content or #content == 0 then
      return
    end

    local text = table.concat(content, '\n')
    if vim.v.event.regtype == 'V' then
      text = text .. '\n'
    end

    if vim.system then
      vim.system({ 'pbcopy' }, { stdin = text })
    else
      vim.fn.system('pbcopy', text)
    end
  end,
})

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

-- システムクリップボードから貼り付け
vim.keymap.set({'n', 'v'}, '<leader>v', function()
  local handle = io.popen('pbpaste')
  if handle then
    local content = handle:read('*a')
    handle:close()
    if content and #content > 0 then
      -- 末尾の改行を削除
      if content:sub(-1) == '\n' then
        content = content:sub(1, -2)
      end
      local lines = vim.split(content, '\n', {plain = true})
      vim.api.nvim_put(lines, 'c', true, true)
    end
  end
end, { noremap = true, desc = 'システムクリップボードから貼り付け' })

-- バッファ操作
vim.keymap.set('n', '<S-h>', ':bprevious<CR>', { noremap = true, silent = true, desc = '前のバッファ' })
vim.keymap.set('n', '<S-l>', ':bnext<CR>', { noremap = true, silent = true, desc = '次のバッファ' })
vim.keymap.set('n', '<leader>bd', function()
  local buf = vim.api.nvim_get_current_buf()
  -- 前のバッファに切り替えてから削除（ウィンドウレイアウトを保持）
  vim.cmd('bprevious')
  vim.api.nvim_buf_delete(buf, { force = false })
end, { noremap = true, silent = true, desc = 'バッファを閉じる' })
