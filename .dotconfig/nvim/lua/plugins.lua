-- lazy.nvimでプラグインを管理
--
-- セキュリティ関連の opts は AGENTS.md の「Neovim プラグイン管理のセキュリティ規律」を参照。
-- サプライチェーン攻撃の攻撃面を狭めるため、rocks / pkg を明示的に無効化している。

-- pyproject.toml に [tool.black] があるディレクトリを探す (conform の cwd / condition 用)。
-- conform 組み込みの prettier が package.json の prettier キーを読むのと同じ手法。
-- vim.fs.root は上方向探索なので、モノレポで sub package だけ black という構成にも追従する。
local function black_root(_, ctx)
	return vim.fs.root(ctx.dirname, function(name, path)
		if name ~= "pyproject.toml" then
			return false
		end
		local f = io.open(vim.fs.joinpath(path, name), "r")
		if not f then
			return false
		end
		local content = f:read("*a") or ""
		f:close()
		return content:match("%[tool%.black%]") ~= nil
	end)
end

-- 設定ファイルが見つからなかった formatter を、対象ファイル自身のディレクトリで動かすための cwd。
-- prettier 系は cwd の .gitignore / .prettierignore を読むため、cwd が nil のままだと conform が
-- nvim の cwd で起動し、無関係なリポジトリの ignore に巻き込まれて黙って no-op になる。
local function own_dir(_, ctx)
	return ctx.dirname
end

-- prettier 系の候補リスト。prettierd (常駐デーモン) が速いので優先し、未導入なら prettier に落ちる。
-- 末尾の *_default は設定ファイルが無いときの最後の砦。
local prettier_formatters =
	{ "prettierd", "prettier", "prettierd_default", "prettier_default", stop_after_first = true }
-- biome も候補に含む ft 用 (biome.json があれば biome が勝つ)
local web_formatters =
	{ "biome", "prettierd", "prettier", "prettierd_default", "prettier_default", stop_after_first = true }

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
			local actions = require("telescope.actions")
			telescope.setup({
				defaults = {
					path_display = { "filename_first" },
					mappings = {
						i = {
							["<Esc>"] = actions.close,
						},
					},
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
			{
				"<leader>fk",
				function()
					require("command_palette").open()
				end,
				desc = "コマンドパレットを開く",
			},
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

	-- 構文解析
	-- nvim-treesitter は 2026-04 にアーカイブされ、main ブランチのリライトが最終形となった。
	-- 新 API: パーサ導入は require('nvim-treesitter').install、ハイライトは
	-- FileType autocmd で vim.treesitter.start() を呼ぶ方式（旧 ensure_installed /
	-- auto_install / highlight オプションは廃止）。lazy-load も非対応。
	--
	-- リポジトリは archive 済みで main ブランチの HEAD は恒久的に下記 commit。
	-- branch 追従ではなく spec で commit を直接固定することで、サプライチェーン経路
	-- (フォーク乗っ取り / アーカイブ解除後の悪意ある commit など) を物理的に塞ぐ。
	{
		"nvim-treesitter/nvim-treesitter",
		commit = "4916d6592ede8c07973490d9322f187e07dfefac",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			-- markdown_inline はフェンスコードブロック注入 (LSP ホバー等) で各言語の
			-- ハイライトを得るために必要。auto_install 相当は新 API にないため、
			-- 必要なパーサはここで明示する。
			local parsers = {
				"markdown",
				"markdown_inline",
				"lua",
				"go",
				"python",
				"typescript",
				"tsx",
				"javascript",
				"bash",
				"yaml",
				"json",
				"css",
				"terraform",
				"hcl",
			}
			require("nvim-treesitter").install(parsers)

			-- main 版の nvim-treesitter には jsonc パーサが無い (旧 master にはあった)。
			-- jsonc は json パーサで解析できるため filetype をマップしておく。
			-- これが無いと jsonc バッファで treesitter ハイライトが効かない。
			vim.treesitter.language.register("json", "jsonc")

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("dotfiles_treesitter", { clear = true }),
				callback = function(args)
					-- パーサ未導入の filetype では静かに失敗させる
					pcall(vim.treesitter.start, args.buf)
				end,
			})
		end,
	},

	-- スコープ（見出し・関数・クラス）を画面上部にスティッキー表示
	-- VSCode の sticky scroll 相当。Markdown では H1 > H2 > H3 ... が階層的に積まれる。
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = { "BufReadPost", "BufNewFile" },
		main = "treesitter-context",
		opts = {
			enable = true,
			max_lines = 0,
			min_window_height = 0,
			line_numbers = true,
			multiline_threshold = 20,
			trim_scope = "outer",
			mode = "topline",
			separator = nil,
			zindex = 20,
		},
		keys = {
			{
				"[c",
				function()
					require("treesitter-context").go_to_context(vim.v.count1)
				end,
				desc = "親コンテキスト（見出し/関数）にジャンプ",
				silent = true,
			},
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
			{ "<leader>pmm", "<cmd>RenderMarkdown toggle<CR>", desc = "Markdownレンダリング切り替え" },
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

	-- 右端の概要ルーラー付きスクロールバー (VSCode 相当)
	-- 本文の表示幅を奪わないよう、ミニマップではなく右端のフローティングバーに情報を重ねる。
	-- タグを打っていないリポジトリなので version / commit は書かず、lazy-lock.json を信頼の源とする。
	-- build フィールドを持たないため install 時に任意スクリプトが走る攻撃面はない。
	{
		"lewis6991/satellite.nvim",
		dependencies = { "lewis6991/gitsigns.nvim" },
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			-- 上流 README には width があるが現在のソースに実装がなく、バーの幅は 1 桁固定
			winblend = 50,
			-- UI 用バッファではスクロールバーを描かない (二重表示を避ける)
			excluded_filetypes = {
				"NvimTree",
				"aerial",
				"toggleterm",
				"trouble",
				"lazy",
				"TelescopePrompt",
				"help",
			},
			handlers = {
				cursor = { enable = true },
				search = { enable = true },
				diagnostic = { enable = true },
				-- overlap = true でバー本体に重ねる。既定の false は
				-- バーの右隣に専用カラムを作る挙動で、バーが画面最右端にあると描画されない。
				-- 記号は上の gitsigns.signs と見た目を揃える
				gitsigns = {
					enable = true,
					overlap = true,
					signs = { add = "│", change = "│", delete = "-" },
				},
				marks = { enable = false },
				quickfix = { enable = false },
			},
		},
	},

	-- バッファライン（タブ表示）
	{
		"akinsho/bufferline.nvim",
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
				["<C-e>"] = { "cancel", "fallback" },
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
	-- filetype ごとに formatter の「候補リスト」を持ち、プロジェクトの設定ファイルの有無で
	-- 実際に使うものを決める (VSCode がワークスペースの設定ファイルを見るのと同じ発想)。
	--   * cwd         : formatter を実行するディレクトリ。prettier/biome は起動ディレクトリを
	--                   基点に上方向へ自分の設定ファイルを探すため、conform 側で「設定ファイルの
	--                   あるディレクトリ」を探してそこで実行する。組み込み定義に含まれている。
	--   * require_cwd : 上記の探索が失敗したらその formatter を使わない。
	--                   = 「設定ファイルが無い → このプロジェクトはこのツールを使っていない」の判定。
	-- 上方向探索なのでモノレポのネストにも自動で追従する。
	-- どの formatter が選ばれた/スキップされたかは :ConformInfo で確認できる。
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			formatters_by_ft = {
				-- biome.json → biome / .prettierrc 系 → prettierd / どちらも無ければ既定値。
				-- prettierd (常駐デーモン) を優先し、未導入なら prettier に落ちる。
				javascript = web_formatters,
				typescript = web_formatters,
				javascriptreact = web_formatters,
				typescriptreact = web_formatters,
				json = web_formatters,
				jsonc = web_formatters,
				css = web_formatters,
				graphql = web_formatters,
				-- biome が扱わない ft は prettier 系のみ
				html = prettier_formatters,
				scss = prettier_formatters,
				less = prettier_formatters,
				vue = prettier_formatters,
				yaml = prettier_formatters,

				-- pyproject.toml に [tool.black] があれば isort + black、無ければ ruff。
				-- import 整理と整形の 2 段構成なので stop_after_first は使わず、
				-- 各 formatter 側の require_cwd / condition で排他にする。
				python = { "isort", "black", "ruff_organize_imports", "ruff_format" },

				-- ツール自身が上方向に設定を探し、無ければ既定値で動く ft。
				-- 候補が 1 つなので require_cwd は付けない (= 常に有効)。
				lua = { "stylua" }, -- --search-parent-directories で .stylua.toml を自力探索
				go = { "gofumpt" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt_zsh" },
				terraform = { "terraform_fmt" },
				hcl = { "terraform_fmt" },
				toml = { "taplo" },
			},
			formatters = {
				-- 設定ファイルのあるプロジェクトでのみ「本来の担当」として使う
				biome = { require_cwd = true },
				prettierd = { require_cwd = true },
				prettier = { require_cwd = true },
				-- 最後の砦: 設定ファイルが無くても prettier のデフォルト設定で整形する
				-- (VSCode の Prettier 拡張が prettier.requireConfig = false で振る舞うのと同じ)
				prettierd_default = {
					inherit = "prettierd",
					require_cwd = false,
					cwd = own_dir,
				},
				prettier_default = {
					inherit = "prettier",
					require_cwd = false,
					cwd = own_dir,
				},

				-- Python: black 検出時のみ isort + black、そうでなければ ruff
				black = { cwd = black_root, require_cwd = true },
				isort = { cwd = black_root, require_cwd = true },
				ruff_organize_imports = {
					condition = function(_, ctx)
						return black_root(nil, ctx) == nil
					end,
				},
				ruff_format = {
					condition = function(_, ctx)
						return black_root(nil, ctx) == nil
					end,
				},

				-- zsh: shfmt は zsh 非対応なので bash として解釈させる。
				-- zsh 固有構文 (zstyle, ${(f)...} 等) を含むファイルは shfmt がパースエラーで
				-- 停止するだけで、壊れた出力は生成されない。エラー通知は format_on_save 側で抑制する。
				shfmt_zsh = { inherit = "shfmt", prepend_args = { "-ln", "bash" } },
			},
			-- ft 単位でトグル可能 (:FormatToggle / format_toggle.lua)。
			-- nil を返すと conform は保存時フォーマットをスキップする。
			format_on_save = function(bufnr)
				if require("format_toggle").is_disabled(bufnr) then
					return nil
				end
				return {
					timeout_ms = 1500,
					lsp_format = "fallback",
					-- zsh は shfmt がパースできないファイルが混ざるため、失敗通知を抑制する
					quiet = vim.bo[bufnr].filetype == "zsh",
				}
			end,
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
	-- formatter (conform) と同じ発想で、プロジェクトの設定ファイルの有無で使う linter を決める。
	-- VSCode の実態に合わせて 2 種類に分ける:
	--   * 設定ファイル不要 (shellcheck / yamllint / hadolint) → 常に有効
	--   * 設定ファイル必須 (eslint / golangci-lint / tflint) → 見つかったときだけ有効
	-- nvim-lint には conform の require_cwd / executable チェックに相当する機能が無いので、
	-- ここで自前に候補を絞り込む。有効な linter は :LintInfo で確認できる。
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "InsertLeave" },
		config = function()
			local ESLINT_CONFIG = {
				"eslint.config.js",
				"eslint.config.mjs",
				"eslint.config.cjs",
				"eslint.config.ts",
				".eslintrc",
				".eslintrc.js",
				".eslintrc.cjs",
				".eslintrc.json",
				".eslintrc.yaml",
				".eslintrc.yml",
			}
			local GOLANGCI_CONFIG = { ".golangci.yml", ".golangci.yaml", ".golangci.toml", ".golangci.json" }

			-- name: nvim-lint の linter 名 / cmd: 実行ファイル名 / config: nil なら設定ファイル不要
			local eslint = { name = "eslint_d", cmd = "eslint_d", config = ESLINT_CONFIG }
			local candidates = {
				sh = { { name = "shellcheck", cmd = "shellcheck" } },
				bash = { { name = "shellcheck", cmd = "shellcheck" } },
				yaml = { { name = "yamllint", cmd = "yamllint" } },
				dockerfile = { { name = "hadolint", cmd = "hadolint" } },
				javascript = { eslint },
				typescript = { eslint },
				javascriptreact = { eslint },
				typescriptreact = { eslint },
				go = { { name = "golangcilint", cmd = "golangci-lint", config = GOLANGCI_CONFIG } },
				terraform = { { name = "tflint", cmd = "tflint", config = { ".tflint.hcl" } } },
			}

			-- 有効な linter 名と、除外されたものの理由を返す
			local function resolve(bufnr)
				local names, skipped = {}, {}
				for _, c in ipairs(candidates[vim.bo[bufnr].filetype] or {}) do
					if vim.fn.executable(c.cmd) ~= 1 then
						table.insert(skipped, c.name .. " (未導入: " .. c.cmd .. ")")
					elseif c.config and not vim.fs.root(bufnr, c.config) then
						table.insert(skipped, c.name .. " (設定ファイルなし)")
					else
						table.insert(names, c.name)
					end
				end
				return names, skipped
			end

			local augroup = vim.api.nvim_create_augroup("dotfiles_nvim_lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				group = augroup,
				callback = function(args)
					local names = resolve(args.buf)
					if #names > 0 then
						require("lint").try_lint(names)
					end
				end,
			})

			vim.api.nvim_create_user_command("LintInfo", function()
				local names, skipped = resolve(0)
				local ft = vim.bo.filetype
				local lines = { string.format("filetype: %s", ft ~= "" and ft or "(なし)") }
				table.insert(lines, "有効: " .. (#names > 0 and table.concat(names, ", ") or "(なし)"))
				if #skipped > 0 then
					table.insert(lines, "除外: " .. table.concat(skipped, ", "))
				end
				vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
			end, { desc = "現バッファで有効な linter と、除外された linter の理由を表示" })
		end,
	},

	-- キーマップ即時参照 (leader / g キー押下後にポップアップで候補表示)
	-- 個別キーは vim.keymap.set 時の desc を which-key が自動で読み取るため、
	-- ここではグループ名と Neovim 0.12 デフォルト LSP キーの説明のみ宣言する。
	{
		"folke/which-key.nvim",
		version = "^3",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			delay = 250,
			icons = { mappings = true },
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			wk.add({
				-- leader 配下のグループ名
				{ "<leader>f", group = "Find" },
				{ "<leader>l", group = "LSP" },
				{ "<leader>x", group = "Diagnostics" },
				{ "<leader>b", group = "Buffer" },
				{ "<leader>p", group = "Preview" },
				{ "<leader>pm", group = "Markdown" },
				{ "<leader>pmc", group = "cmux" },

				-- Neovim 0.12 デフォルト LSP キー (g プレフィックス)
				{ "gr", group = "LSP Refactor/References" },
				{ "grn", desc = "LSP: シンボル名変更 (rename)" },
				{ "gra", desc = "LSP: コードアクション" },
				{ "grr", desc = "LSP: 参照一覧 (Telescope)" },
				{ "gri", desc = "LSP: 実装にジャンプ" },
				{ "grt", desc = "LSP: 型定義にジャンプ" },
				{ "gO", desc = "LSP: ドキュメント内シンボル一覧" },
			})
		end,
	},
}, {
	-- 起動中の設定ファイル変更検出を無効化 (意図しないリロードを避ける)
	change_detection = {
		enabled = false,
		notify = false,
	},
	-- 自動更新チェック無効 (明示)。更新は :Lazy update を手動実行する運用
	checker = {
		enabled = false,
		check_pinned = false,
	},
	-- luarocks 経由のパッケージソースを無効化 (攻撃面削減、現状未使用)
	rocks = {
		enabled = false,
	},
	-- 追加パッケージソース (rockspec / .lazy.lua 等) を無効化 (同上)
	pkg = {
		enabled = false,
	},
	-- 既存挙動維持: 起動時に欠落プラグインを lockfile の commit で install
	install = {
		missing = true,
	},
	-- partial clone (--filter=blob:none) を維持
	git = {
		filter = true,
		timeout = 120,
	},
})
