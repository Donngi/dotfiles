require("nvim-tree").setup({
  sort_by = "case_sensitive",
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
  git = {
    enable = true,
    ignore = false
  },
  -- ファイルシステム監視を無効化（終了時のハング対策）
  -- 外部でファイルが変更された場合は手動でR（リフレッシュ）が必要
  filesystem_watchers = {
    enable = false,
  },
})

-- 手動トグル用のキーマッピング
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })