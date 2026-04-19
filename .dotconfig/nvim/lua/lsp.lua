-- LSP (Language Server Protocol) 設定
-- nvim 0.11+ の vim.lsp.config / vim.lsp.enable API を使用
-- Phase 0: lua_ls のみ有効化、最小限の on_attach

local M = {}

-- 診断表示の共通設定
local function setup_diagnostic()
	vim.diagnostic.config({
		virtual_text = { prefix = "●", spacing = 2 },
		signs = true,
		underline = true,
		update_in_insert = false,
		severity_sort = true,
		float = { border = "rounded", source = true },
	})
end

-- LSP アタッチ時にバッファローカルで有効化するキーマップ・機能
local function on_attach(client, bufnr)
	local opts = { buffer = bufnr, silent = true }

	-- 0.12 デフォルト (K, grn, gra, grr, gri, grt, gO, <C-S>, grx) はそのまま使う
	-- ここでは 0.12 デフォルトに含まれない・補完したいキーのみ追加する
	vim.keymap.set(
		"n",
		"gd",
		vim.lsp.buf.definition,
		vim.tbl_extend("force", opts, { desc = "LSP: 定義にジャンプ" })
	)
	vim.keymap.set(
		"n",
		"gD",
		vim.lsp.buf.declaration,
		vim.tbl_extend("force", opts, { desc = "LSP: 宣言にジャンプ" })
	)

	vim.keymap.set("n", "<leader>lf", function()
		require("conform").format({ async = true, lsp_format = "fallback" })
	end, vim.tbl_extend("force", opts, { desc = "手動フォーマット" }))

	vim.keymap.set(
		"n",
		"<leader>le",
		vim.diagnostic.open_float,
		vim.tbl_extend("force", opts, { desc = "LSP: 診断ポップアップ" })
	)

	-- inlay hints (サーバーが対応していればトグル可能)
	if client and client:supports_method("textDocument/inlayHint") then
		vim.keymap.set("n", "<leader>lh", function()
			local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
			vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
		end, vim.tbl_extend("force", opts, { desc = "LSP: inlay hints トグル" }))
	end
end

-- サーバー定義テーブル
local servers = {
	lua_ls = {
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" } },
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
				telemetry = { enable = false },
			},
		},
	},

	gopls = {
		settings = {
			gopls = {
				gofumpt = true,
				usePlaceholders = true,
				staticcheck = true,
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					compositeLiteralTypes = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
				codelenses = {
					generate = true,
					test = true,
					tidy = true,
					upgrade_dependency = true,
				},
			},
		},
	},

	-- pyright は型推論を担当 (lint/format・import organize は ruff に委譲)
	pyright = {
		settings = {
			pyright = {
				disableOrganizeImports = true,
			},
			python = {
				analysis = {
					typeCheckingMode = "basic",
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					diagnosticMode = "openFilesOnly",
					-- ruff と重複する lint 寄り診断を抑制 (型診断は維持)
					diagnosticSeverityOverrides = {
						reportUnusedImport = "none",
						reportUnusedVariable = "none",
						reportUnusedFunction = "none",
						reportUnusedClass = "none",
					},
				},
			},
		},
	},

	-- ruff は lint + format + import organize を担当
	ruff = {
		init_options = {
			settings = {
				organizeImports = true,
				lint = { enable = true },
			},
		},
	},

	vtsls = {
		settings = {
			typescript = {
				inlayHints = {
					parameterNames = { enabled = "literals" },
					parameterTypes = { enabled = true },
					variableTypes = { enabled = true },
					propertyDeclarationTypes = { enabled = true },
					functionLikeReturnTypes = { enabled = true },
				},
			},
			javascript = {
				inlayHints = {
					parameterNames = { enabled = "literals" },
					parameterTypes = { enabled = true },
					variableTypes = { enabled = true },
					propertyDeclarationTypes = { enabled = true },
					functionLikeReturnTypes = { enabled = true },
				},
			},
		},
	},

	bashls = {},

	-- YAML: 代表的なスキーマを自動判定して検証
	yamlls = {
		settings = {
			yaml = {
				keyOrdering = false,
				format = { enable = true },
				validate = true,
				schemaStore = {
					enable = true,
					url = "https://www.schemastore.org/api/json/catalog.json",
				},
			},
		},
	},

	terraformls = {},

	-- biome: JS/TS/JSON/CSS/GraphQL 向け LSP + formatter + linter
	-- プロジェクトに biome.json が存在する場合のみアタッチする (nvim-lspconfig デフォルト)
	biome = {},
}

-- blink.cmp の config から呼ばれる。capabilities を受け取って各サーバーに注入する。
function M.setup(capabilities)
	setup_diagnostic()

	local augroup = vim.api.nvim_create_augroup("dotfiles_lsp_attach", { clear = true })
	vim.api.nvim_create_autocmd("LspAttach", {
		group = augroup,
		callback = function(args)
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			on_attach(client, args.buf)
		end,
	})

	for name, config in pairs(servers) do
		config.capabilities = vim.tbl_deep_extend(
			"force",
			vim.lsp.protocol.make_client_capabilities(),
			capabilities or {},
			config.capabilities or {}
		)
		vim.lsp.config(name, config)
		vim.lsp.enable(name)
	end
end

return M
