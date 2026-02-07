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
        enable = true,
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
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = {
            "%.git/",
            "node_modules/",
            "%.venv/",
            "__pycache__/",
            "dist/",
            "build/",
            "target/",
            "vendor/",
            "deps/",
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            no_ignore = true,
          },
          live_grep = {
            additional_args = { "--hidden", "--no-ignore" },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })
      telescope.load_extension("fzf")
    end,
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

      -- ターミナルカラーを Iceberg Dark に合わせる（Ghostty と統一）
      vim.g.terminal_color_0  = "#161821"  -- black
      vim.g.terminal_color_1  = "#e27878"  -- red
      vim.g.terminal_color_2  = "#b4be82"  -- green
      vim.g.terminal_color_3  = "#e2e2bf"  -- yellow (Ghostty カスタム)
      vim.g.terminal_color_4  = "#84a0c6"  -- blue
      vim.g.terminal_color_5  = "#a093c7"  -- magenta
      vim.g.terminal_color_6  = "#89b8c2"  -- cyan
      vim.g.terminal_color_7  = "#c6c8d1"  -- white
      vim.g.terminal_color_8  = "#6b7089"  -- bright black
      vim.g.terminal_color_9  = "#e98989"  -- bright red
      vim.g.terminal_color_10 = "#c0ca8e"  -- bright green
      vim.g.terminal_color_11 = "#e9b189"  -- bright yellow
      vim.g.terminal_color_12 = "#91acd1"  -- bright blue
      vim.g.terminal_color_13 = "#ada0d3"  -- bright magenta
      vim.g.terminal_color_14 = "#95c4ce"  -- bright cyan
      vim.g.terminal_color_15 = "#d2d4de"  -- bright white
    end,
  },

  -- マルチカーソル
  {
    "mg979/vim-visual-multi",
  },

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

  -- スムーススクロール
  {
    "karb94/neoscroll.nvim",
    opts = {
      mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
      duration_multiplier = 0.5,  -- アニメーション速度（小さいほど速い）
    },
  },

  -- Git変更表示
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
  },

  -- バッファライン（タブ表示）
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = {
        mode = "buffers",
        separator_style = "thin",
        show_buffer_close_icons = true,
        show_close_icon = true,
        color_icons = true,
        always_show_bufferline = true,
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            text_align = "center",
            separator = true,
          },
        },
      },
    },
  },

  -- フローティングターミナル
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = 20,
      open_mapping = [[<C-\>]],
      direction = "float",
      shade_terminals = false,
      float_opts = {
        border = "curved",
      },
    },
  },
})
