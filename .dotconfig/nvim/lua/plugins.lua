-- lazy.nvimでプラグインを管理
require("lazy").setup({
	-- ファイルエクスプローラー
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			view = {
				width = {
					min = 30,
					max = 50,
				},
			},
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
			update_focused_file = {
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
			{
				"<leader>ff",
				"<cmd>Telescope find_files<CR>",
				desc = "ファイル名で検索（カレントディレクトリ以下）",
			},
			{
				"<leader>fg",
				"<cmd>Telescope live_grep<CR>",
				desc = "grep検索（カレントディレクトリ以下）",
			},
			{
				"<leader>fn",
				"<cmd>Telescope current_buffer_fuzzy_find<CR>",
				desc = "現在開いているファイル内を検索",
			},
			{ "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "開いているバッファの一覧から選択" },
			{ "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "ヘルプドキュメントを検索" },
		},
	},

	-- カラースキーム
	{
		"Mofiqul/vscode.nvim",
		priority = 1000,
		config = function()
			vim.o.background = "dark"
			require("vscode").setup({})
			require("vscode").load()

			-- ターミナルカラーを Iceberg Dark に合わせる（Ghostty と統一）
			vim.g.terminal_color_0 = "#161821" -- black
			vim.g.terminal_color_1 = "#e27878" -- red
			vim.g.terminal_color_2 = "#b4be82" -- green
			vim.g.terminal_color_3 = "#e2e2bf" -- yellow (Ghostty カスタム)
			vim.g.terminal_color_4 = "#84a0c6" -- blue
			vim.g.terminal_color_5 = "#a093c7" -- magenta
			vim.g.terminal_color_6 = "#89b8c2" -- cyan
			vim.g.terminal_color_7 = "#c6c8d1" -- white
			vim.g.terminal_color_8 = "#6b7089" -- bright black
			vim.g.terminal_color_9 = "#e98989" -- bright red
			vim.g.terminal_color_10 = "#c0ca8e" -- bright green
			vim.g.terminal_color_11 = "#e9b189" -- bright yellow
			vim.g.terminal_color_12 = "#91acd1" -- bright blue
			vim.g.terminal_color_13 = "#ada0d3" -- bright magenta
			vim.g.terminal_color_14 = "#95c4ce" -- bright cyan
			vim.g.terminal_color_15 = "#d2d4de" -- bright white
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

	-- Markdown バッファ内レンダリング
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = "markdown",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			enabled = false,
		},
		keys = {
			{ "<leader>pm", "<cmd>RenderMarkdown toggle<CR>", desc = "Markdownレンダリング切り替え" },
		},
	},

	-- スムーススクロール
	{
		"karb94/neoscroll.nvim",
		opts = {
			mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
			duration_multiplier = 0.5, -- アニメーション速度（小さいほど速い）
		},
	},

	-- Git変更表示
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "│" },
				change = { text = "│" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
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

	-- 補完エンジン
	-- preset = "none" を必ず指定して、既存の Emacs 風キーバインド
	-- (<C-f>/<C-b>/<C-a>/<C-e>/<C-h>/<C-d>/<C-k>) を温存する。
	-- <C-n>/<C-p> は補完メニュー表示中のみ候補選択に使い、
	-- メニュー非表示時は fallback で base.lua の <Down>/<Up> 相当へ戻す。
	{
		"saghen/blink.cmp",
		version = "1.*",
		lazy = true,
		opts = {
			keymap = {
				preset = "none",
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<C-y>"] = { "select_and_accept", "fallback" },
				["<C-g>"] = { "cancel", "fallback" },
			},
			completion = {
				menu = { border = "rounded" },
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 300,
					window = { border = "rounded" },
				},
				list = { selection = { preselect = false, auto_insert = false } },
			},
			signature = { enabled = true, window = { border = "rounded" } },
			snippets = { preset = "default" }, -- 組み込みの vim.snippet を使用
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
	},

	-- LSP サーバー定義の供給元 (起動は vim.lsp.config/enable で行う)
	-- ファイルを開いたタイミング (BufReadPre/BufNewFile) でロードして LSP をアタッチする。
	-- blink.cmp を dependencies に入れることで、先にロード・setup させて capabilities を取得できる。
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "saghen/blink.cmp" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			require("lsp").setup(capabilities)
		end,
	},

	-- LSP プログレス表示 (右下に spinner)
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {
			notification = {
				window = { winblend = 0 },
			},
		},
	},

	-- フォーマッター
	-- 保存時に filetype ごとの formatter を呼ぶ。未登録 filetype は LSP フォーマットにフォールバック。
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "gofumpt" },
				python = { "ruff_organize_imports", "ruff_format" },
				javascript = { "biome" },
				typescript = { "biome" },
				javascriptreact = { "biome" },
				typescriptreact = { "biome" },
				json = { "biome" },
				jsonc = { "biome" },
				css = { "biome" },
				graphql = { "biome" },
				sh = { "shfmt" },
				bash = { "shfmt" },
			},
			format_on_save = {
				timeout_ms = 1500,
				lsp_format = "fallback",
			},
		},
	},

	-- 診断・参照・シンボル一覧 UI
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {},
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<CR>",
				desc = "診断一覧 (プロジェクト全体)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
				desc = "診断一覧 (現バッファ)",
			},
			{ "<leader>xs", "<cmd>Trouble lsp_document_symbols toggle<CR>", desc = "シンボル一覧" },
			{ "<leader>xr", "<cmd>Trouble lsp_references toggle<CR>", desc = "LSP 参照一覧" },
		},
	},

	-- リンター (保存時に外部 linter を走らせて vim.diagnostic に流す)
	-- Phase 1: 骨格のみ。linters_by_ft は Phase 3 以降で言語別に追加する。
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "InsertLeave" },
		config = function()
			require("lint").linters_by_ft = {
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				yaml = { "yamllint" },
			}

			local augroup = vim.api.nvim_create_augroup("dotfiles_nvim_lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				group = augroup,
				callback = function(args)
					local ft = vim.bo[args.buf].filetype
					if require("lint").linters_by_ft[ft] then
						require("lint").try_lint()
					end
				end,
			})
		end,
	},
})
