-- lazy.nvimでプラグインを管理
require("lazy").setup({
  -- ファイルエクスプローラー
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      sort_by = "case_sensitive",
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
      },
      git = {
        enable = true,
        ignore = false,
      },
      filesystem_watchers = {
        enable = false,
      },
    },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "ファイルツリー切り替え" },
    },
  },

  -- ファジーファインダー
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      defaults = {
        file_ignore_patterns = { "%.git/" },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
        live_grep = {
          additional_args = { "--hidden" },
        },
      },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "ファイル名で検索（カレントディレクトリ以下）" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "grep検索（カレントディレクトリ以下）" },
      { "<leader>fn", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "現在開いているファイル内を検索" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "開いているバッファの一覧から選択" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "ヘルプドキュメントを検索" },
    },
  },

  -- カラースキーム
  {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    config = function()
      vim.o.background = 'dark'
      require('vscode').setup({})
      require('vscode').load()
    end,
  },

  -- マルチカーソル
  { "mg979/vim-visual-multi" },

  -- 構文解析
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "markdown", "markdown_inline", "lua" },
      auto_install = true,
      highlight = { enable = true },
    },
  },

  -- アウトライン表示（目次）
  {
    "stevearc/aerial.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      layout = { default_direction = "prefer_right" },
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle!<CR>", desc = "アウトライン表示の切り替え" },
    },
  },
})
