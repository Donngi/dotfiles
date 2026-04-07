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
vim.opt.wildoptions:append('fuzzy') -- コマンド補完でfuzzy matchを有効化（case-insensitive）

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

-- Markdownファイルで箇条書き・引用の自動挿入を有効化
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- gq など整形コマンドから参照される comments 設定（-, *, > を継続対象として認識）
    vim.opt_local.comments = "b:-,b:*,b:>"
    -- formatoptions の r は <CR> マッピングと重複して二重挿入になるため付けない
    vim.opt_local.formatoptions:remove("r")

    -- Markdownアンカーリンクへのジャンプ（目次から見出しへ移動）
    vim.keymap.set('n', '<CR>', function()
      local line = vim.api.nvim_get_current_line()
      -- 行内の最初の [text](#anchor) からアンカーを取得
      local anchor = line:match('%[.-%]%(#(.-)%)')
      if not anchor then return end

      -- 見出しテキストを GitHub 形式アンカーに変換する関数
      local function to_anchor(text)
        local s = text:lower()
        -- ASCII 句読点を除去（ハイフン・スペース・英数字・非ASCII文字は残す）
        s = s:gsub('[%p]', function(c)
          if c == '-' or c == ' ' then return c end
          return ''
        end)
        -- 連続スペースを1つに
        s = s:gsub('%s+', ' ')
        s = s:match('^%s*(.-)%s*$')
        -- スペースをハイフンに
        s = s:gsub(' ', '-')
        return s
      end

      -- 全行を走査して一致する見出しにジャンプ
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      for i, l in ipairs(lines) do
        local heading = l:match('^#+%s+(.*)')
        if heading and to_anchor(heading) == anchor then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          return
        end
      end
    end, { buffer = true, desc = 'Markdownアンカーリンクにジャンプ' })

    -- Tab/Shift-Tabで箇条書きのインデントレベルを変更
    vim.keymap.set('i', '<Tab>', '<C-t>', { buffer = true, desc = 'インデントを上げる' })
    vim.keymap.set('i', '<S-Tab>', '<C-d>', { buffer = true, desc = 'インデントを下げる' })

    -- 引用(>)・箇条書き(-, *)・順序付きリスト(1. )の継続改行。
    -- マーカーのみの空行で改行した場合はプレフィックスを消去してキャンセルする。
    vim.keymap.set('i', '<CR>', function()
      local line = vim.api.nvim_get_current_line()
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))

      -- プレフィックスを検出（順序付きリスト → 引用/箇条書きの順）。
      -- カーソルが行末かつマッチしたときのみ継続/キャンセル処理を行う。
      local indent, next_prefix, rest
      if col == #line then
        local oi, num, orst = line:match('^(%s*)(%d+)%.%s(.-)%s*$')
        if num then
          indent, next_prefix, rest = oi, tostring(tonumber(num) + 1) .. '. ', orst
        else
          local i2, marker, rst = line:match('^(%s*)([>%-%*])%s(.-)%s*$')
          if marker then
            indent, next_prefix, rest = i2, marker .. ' ', rst
          end
        end
      end

      if indent and rest == '' then
        -- マーカーだけの空行: 現在行をクリア、改行は挿入しない
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { '' })
        vim.api.nvim_win_set_cursor(0, { row, 0 })
        return
      end

      if indent then
        -- 次行に indent + 次プレフィックスを挿入
        local new_line = indent .. next_prefix
        vim.api.nvim_buf_set_lines(0, row, row, false, { new_line })
        vim.api.nvim_win_set_cursor(0, { row + 1, #new_line })
        return
      end

      -- 通常の改行: カーソル位置で行を分割
      local before = line:sub(1, col)
      local after = line:sub(col + 1)
      vim.api.nvim_buf_set_lines(0, row - 1, row, false, { before, after })
      vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
    end, { buffer = true, desc = '引用・リストの継続改行' })
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

-- 行の折り返し/サイドスクロールをトグル
vim.keymap.set('n', '<M-z>', function()
  if vim.opt.wrap:get() then
    vim.opt.wrap = false
    vim.opt.sidescroll = 1
    vim.notify('wrap: OFF (side scroll)')
  else
    vim.opt.wrap = true
    vim.opt.sidescroll = 0
    vim.notify('wrap: ON')
  end
end, { noremap = true, desc = '行折り返しをトグル' })

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

-- メモファイルのリネーム
vim.api.nvim_create_user_command('MemoRename', function()
  local current = vim.api.nvim_buf_get_name(0)
  if current == '' then
    vim.notify('バッファにファイルが関連付けられていません', vim.log.levels.WARN)
    return
  end

  local dir = vim.fn.fnamemodify(current, ':h')
  local ext = vim.fn.fnamemodify(current, ':e')
  local stem = vim.fn.fnamemodify(current, ':t:r')

  vim.ui.input({ prompt = 'New name: ', default = stem }, function(new_name)
    if not new_name or new_name == '' or new_name == stem then return end

    local new_path = dir .. '/' .. new_name .. '.' .. ext

    if vim.fn.filereadable(new_path) == 1 then
      vim.notify('同名のファイルが既に存在します: ' .. new_name .. '.' .. ext, vim.log.levels.ERROR)
      return
    end

    vim.cmd('silent write')

    local ok = vim.fn.rename(current, new_path)
    if ok ~= 0 then
      vim.notify('リネームに失敗しました', vim.log.levels.ERROR)
      return
    end

    local old_buf = vim.api.nvim_get_current_buf()
    vim.cmd('edit ' .. vim.fn.fnameescape(new_path))
    vim.api.nvim_buf_delete(old_buf, { force = true })

    -- frontmatter の title を更新
    local lines = vim.api.nvim_buf_get_lines(0, 0, 5, false)
    for i, line in ipairs(lines) do
      if line:match('^title:') then
        vim.api.nvim_buf_set_lines(0, i - 1, i, false, { 'title: ' .. new_name })
        break
      end
    end

    vim.notify('Renamed: ' .. new_name .. '.' .. ext)
  end)
end, { desc = 'メモファイルをリネーム' })
