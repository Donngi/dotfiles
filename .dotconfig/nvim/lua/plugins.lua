-- lazy.nvimでプラグインを管理
require("lazy").setup({
  -- ファイルエクスプローラー
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },

  -- ファジーファインダー
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },

  -- カラースキーム
  { "Mofiqul/vscode.nvim" },

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
