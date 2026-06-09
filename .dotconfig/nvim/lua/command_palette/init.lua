-- コマンドパレット: VSCode の Ctrl+Shift+P 相当
-- 自分定義キーマップ / Neovim 標準操作 / プラグイン ex コマンドを統合し、
-- 日本語の説明文でファジー検索 → 実行できる Telescope picker

local M = {}

-- ───────────────────────────── 定数 ─────────────────────────────

local CATEGORIES = { "keymap", "builtin", "plugin" }

-- ウィンドウ/レイアウト
local LAYOUT = {
	strategy = "vertical",
	preview_height = 0.35,
	width = 0.9,
	height = 0.65,
}

-- 一覧の displayer (group / name / keys)
local LIST_COLS = {
	separator = " ",
	items = {
		{ width = 10 }, -- group (最長 Telescope/Clipboard = 9)
		{ width = 30 }, -- name (最長 Fuzzy find in current buffer = 28)
		{ remaining = true }, -- keys (色付き)
	},
}

-- previewer のインデントとハイライト namespace
local PREVIEW_INDENT = "  "
local PREVIEW_NS = vim.api.nvim_create_namespace("command_palette_preview")

-- ─────────────────────────── ヘルパー ───────────────────────────

local function notify_error(msg)
	vim.notify("CommandPalette: " .. tostring(msg), vim.log.levels.ERROR)
end

-- ex コマンドが現在の Neovim で利用可能かをチェック (kind=cmd のフィルタ用)
local function command_exists(action)
	local first = action:match("^(%S+)")
	if not first then
		return false
	end
	return vim.fn.exists(":" .. first) == 2
end

-- ─────────────────────── エントリ収集とソート ───────────────────────

local function load_category(name)
	local ok, mod = pcall(require, "command_palette.entries." .. name)
	if not ok or type(mod) ~= "table" then
		vim.notify("CommandPalette: failed to load entries." .. name .. ": " .. tostring(mod), vim.log.levels.WARN)
		return {}
	end
	return mod
end

local function build_entries()
	local list = {}
	for _, name in ipairs(CATEGORIES) do
		for _, e in ipairs(load_category(name)) do
			if e.kind ~= "cmd" or command_exists(e.action) then
				table.insert(list, e)
			end
		end
	end
	-- group → name 順に並べる (同 group が固まって A→Z 表示)
	table.sort(list, function(a, b)
		local ga, gb = a.group or "", b.group or ""
		if ga ~= gb then
			return ga < gb
		end
		return (a.name or "") < (b.name or "")
	end)
	return list
end

-- ─────────────────────────── 実行ロジック ───────────────────────────

local function execute_entry(e)
	if e.kind == "cmd" then
		local ok, err = pcall(vim.cmd, e.action)
		if not ok then
			notify_error(err)
		end
	elseif e.kind == "keys" then
		local k = vim.api.nvim_replace_termcodes(e.action, true, false, true)
		-- Keymap カテゴリ (<leader>... 等の自作キー) は remap が必要なので "m"
		-- それ以外 (Builtin の ciw, ma, <C-w>= 等) は誤って remap されないよう "n" (noremap)
		local mode = e.category == "Keymap" and "m" or "n"
		vim.api.nvim_feedkeys(k, mode, false)
	elseif e.kind == "fn" and type(e.action) == "function" then
		local ok, err = pcall(e.action)
		if not ok then
			notify_error(err)
		end
	else
		notify_error("unknown kind " .. tostring(e.kind))
	end
end

-- ──────────────────────────── Previewer ────────────────────────────

-- previewer に書き込む行 + ハイライト範囲を作る
local function preview_lines_for(e)
	local lines = {}
	local hls = {}

	local function add(label, value, value_hl)
		if value == nil or value == "" then
			return
		end
		local line = label .. value
		table.insert(lines, line)
		table.insert(hls, {
			lnum = #lines - 1,
			label_end = #label,
			label_hl = "Identifier",
			value_hl = value_hl,
			value_start = #label,
			value_end = #line,
		})
	end

	local action_text
	if type(e.action) == "function" then
		action_text = "<lua function>"
	else
		action_text = tostring(e.action)
	end

	add("Name:     ", e.name)
	add("Group:    ", e.group)
	add("Category: ", e.category)
	add("Keymap:   ", e.keys, "Number")
	add("Kind:     ", e.kind)
	add("Action:   ", action_text, e.kind == "cmd" and "Statement" or nil)

	if e.desc and e.desc ~= "" then
		table.insert(lines, "")
		table.insert(lines, "説明:")
		table.insert(hls, {
			lnum = #lines - 1,
			label_end = #"説明:",
			label_hl = "Title",
		})
		for _, l in ipairs(vim.split(e.desc, "\n", { plain = true })) do
			table.insert(lines, PREVIEW_INDENT .. l)
		end
	end

	return lines, hls
end

local function apply_preview_highlights(bufnr, hls)
	vim.api.nvim_buf_clear_namespace(bufnr, PREVIEW_NS, 0, -1)
	for _, h in ipairs(hls) do
		vim.api.nvim_buf_add_highlight(bufnr, PREVIEW_NS, h.label_hl, h.lnum, 0, h.label_end)
		if h.value_hl and h.value_start then
			vim.api.nvim_buf_add_highlight(bufnr, PREVIEW_NS, h.value_hl, h.lnum, h.value_start, h.value_end)
		end
	end
end

local function build_previewer()
	local previewers = require("telescope.previewers")
	return previewers.new_buffer_previewer({
		title = "Command Details",
		define_preview = function(self, entry)
			local lines, hls = preview_lines_for(entry.value)
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
			apply_preview_highlights(self.state.bufnr, hls)
		end,
	})
end

-- ───────────────────────────── Entry maker ─────────────────────────────

-- 表示用の keys ヒント:
--   keys フィールドがあればそれを優先 (ユーザー設定の <leader>ff 等)
--   無く action 自体がキー入力なら (ciw, zz, ma 等) action を出す
local function keys_hint_for(e)
	if e.keys and e.keys ~= "" then
		return e.keys
	end
	if e.kind == "keys" then
		return e.action
	end
	return ""
end

local function ordinal_for(e)
	return table.concat({
		e.group or "",
		e.name or "",
		e.desc or "",
		e.keys or "",
		e.category or "",
	}, " ")
end

local function build_entry_maker(displayer)
	return function(e)
		return {
			value = e,
			ordinal = ordinal_for(e),
			display = function()
				return displayer({
					{ e.group or "", "TelescopeResultsIdentifier" },
					{ e.name, "TelescopeResultsNormal" },
					{ keys_hint_for(e), "TelescopeResultsNumber" },
				})
			end,
		}
	end
end

-- ───────────────────────────── 公開 API ─────────────────────────────

function M.open(opts)
	opts = opts or {}

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local entry_display = require("telescope.pickers.entry_display")

	local displayer = entry_display.create(LIST_COLS)

	pickers
		.new(opts, {
			prompt_title = "Command Palette",
			layout_strategy = LAYOUT.strategy,
			layout_config = {
				preview_height = LAYOUT.preview_height,
				width = LAYOUT.width,
				height = LAYOUT.height,
			},
			sorting_strategy = "ascending",
			finder = finders.new_table({
				results = build_entries(),
				entry_maker = build_entry_maker(displayer),
			}),
			sorter = conf.generic_sorter(opts),
			previewer = build_previewer(),
			attach_mappings = function(bufnr, _)
				actions.select_default:replace(function()
					local sel = action_state.get_selected_entry()
					actions.close(bufnr)
					if not sel then
						return
					end
					-- Telescope close 後の autocmd と競合しないよう schedule
					vim.schedule(function()
						execute_entry(sel.value)
					end)
				end)
				return true
			end,
		})
		:find()
end

return M
