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
        dotfiles = true,
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
    opts = {},
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "ファイル検索" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "文字列検索" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "バッファ一覧" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "ヘルプ検索" },
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
