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
})
