-- コマンドパレット: プラグイン由来の ex コマンド
-- desc は 2 行構成: 1 行目=動作の説明、2 行目=呼び出すコマンド or 補足
-- 実在チェック (init.lua の build_entries() 側) で未導入プラグインのものは自動除外される

return {
	-- Telescope 追加ピッカー
	{
		group = "Telescope",
		name = "Recent files",
		desc = "最近開いたファイル一覧\n:Telescope oldfiles",
		category = "Plugin",
		kind = "cmd",
		action = "Telescope oldfiles",
	},
	{
		group = "Telescope",
		name = "Command history",
		desc = "コマンド履歴\n:Telescope command_history",
		category = "Plugin",
		kind = "cmd",
		action = "Telescope command_history",
	},
	{
		group = "Telescope",
		name = "Search history",
		desc = "検索履歴\n:Telescope search_history",
		category = "Plugin",
		kind = "cmd",
		action = "Telescope search_history",
	},
	{
		group = "Telescope",
		name = "List all pickers",
		desc = "Telescope に登録されている全ピッカー一覧\n:Telescope builtin",
		category = "Plugin",
		kind = "cmd",
		action = "Telescope builtin",
	},

	-- Trouble
	{
		group = "Trouble",
		name = "Workspace diagnostics",
		desc = "診断一覧 (プロジェクト全体)\n:Trouble diagnostics toggle",
		category = "Plugin",
		kind = "cmd",
		action = "Trouble diagnostics toggle",
	},
	{
		group = "Trouble",
		name = "Buffer diagnostics",
		desc = "診断一覧 (現在のバッファ)\n:Trouble diagnostics toggle filter.buf=0",
		category = "Plugin",
		kind = "cmd",
		action = "Trouble diagnostics toggle filter.buf=0",
	},
	{
		group = "Trouble",
		name = "Quickfix list",
		desc = "クイックフィックスを Trouble 形式で\n:Trouble qflist toggle",
		category = "Plugin",
		kind = "cmd",
		action = "Trouble qflist toggle",
	},

	-- Lazy / LSP
	{
		group = "Lazy",
		name = "Plugin manager UI",
		desc = "プラグイン管理 UI\n:Lazy",
		category = "Plugin",
		kind = "cmd",
		action = "Lazy",
	},

	-- Lint (自作: lint_toggle.lua)
	{
		group = "Lint",
		name = "Toggle lint (current filetype)",
		desc = "現バッファの filetype の lint 表示 (LSP + nvim-lint) を on/off。状態は ft ごとに永続化される。\n:LintToggle",
		category = "Plugin",
		kind = "cmd",
		action = "LintToggle",
	},

	{
		group = "LSP",
		name = "Client info",
		desc = "LSP クライアント情報\n:LspInfo",
		category = "Plugin",
		kind = "cmd",
		action = "LspInfo",
	},
	{
		group = "LSP",
		name = "Open log",
		desc = "LSP ログを開く\n:LspLog",
		category = "Plugin",
		kind = "cmd",
		action = "LspLog",
	},

	-- アウトライン
	{
		group = "Aerial",
		name = "Toggle outline",
		desc = "アウトライン (シンボル一覧サイドバー) 切り替え\n:AerialToggle",
		category = "Plugin",
		kind = "cmd",
		action = "AerialToggle",
	},

	-- Gitsigns
	{
		group = "Gitsigns",
		name = "Toggle current line blame",
		desc = "行 blame の表示をトグル\n:Gitsigns toggle_current_line_blame",
		category = "Plugin",
		kind = "cmd",
		action = "Gitsigns toggle_current_line_blame",
	},
	{
		group = "Gitsigns",
		name = "Preview hunk",
		desc = "ハンク diff プレビュー\n:Gitsigns preview_hunk",
		category = "Plugin",
		kind = "cmd",
		action = "Gitsigns preview_hunk",
	},

	-- Markdown 系 (render-markdown プラグイン + 自作 :MarkdownToc)
	{
		group = "Markdown",
		name = "Toggle preview",
		desc = "Markdown プレビューモード ON/OFF (render-markdown)\n:RenderMarkdown toggle",
		category = "Plugin",
		kind = "cmd",
		action = "RenderMarkdown toggle",
	},
	{
		group = "Markdown",
		name = "Insert/update TOC",
		desc = "Markdown 目次を挿入/更新 (base.lua の自作ユーザーコマンド)\n:MarkdownToc",
		category = "Plugin",
		kind = "cmd",
		action = "MarkdownToc",
	},
}
