-- エラー / 警告の永続ログ
-- vim.notify をラップして WARN 以上を JSON Lines でファイルに追記する。
-- 「何をしたときに起きたか」を後から追えるよう、直近のキー入力 / ex コマンド /
-- autocmd イベントをリングバッファに保持し、記録時にスナップショットを同梱する。
--
-- ログ: stdpath("state")/dotfiles/nvim-diag.jsonl (サイズ超過で .1 / .2 にローテーション)
-- 閲覧: :DotfilesLog

local M = {}

-- ───────────────────────────── 定数 ─────────────────────────────

local LOG_DIR = vim.fn.stdpath("state") .. "/dotfiles"
local LOG_FILE = LOG_DIR .. "/nvim-diag.jsonl"

-- ローテーション: このサイズを超えていたら起動時に世代をずらす
local MAX_BYTES = 2 * 1024 * 1024
local MAX_GENERATIONS = 2

-- リングバッファの保持数
local KEEP_KEYS = 50
local KEEP_CMDS = 20
local KEEP_EVENTS = 30

-- コンテキストとして記録する autocmd イベント
local WATCHED_EVENTS = {
	"VimEnter",
	"BufReadPost",
	"BufWritePre",
	"BufWritePost",
	"FileType",
	"LspAttach",
	"LspDetach",
	"DiagnosticChanged",
}

-- :DotfilesLog で一度に表示するレコード数 (新しいものから)
local VIEW_LIMIT = 100

-- ───────────────────────── リングバッファ ─────────────────────────

local function ring_new(limit)
	return { items = {}, limit = limit }
end

local function ring_push(ring, value)
	table.insert(ring.items, value)
	if #ring.items > ring.limit then
		table.remove(ring.items, 1)
	end
end

local function ring_snapshot(ring)
	return vim.deepcopy(ring.items)
end

local keys = ring_new(KEEP_KEYS)
local cmds = ring_new(KEEP_CMDS)
local events = ring_new(KEEP_EVENTS)

-- ─────────────────────────── ヘルパー ───────────────────────────

-- insert / replace / select mode ではキーの中身を残さない。
-- パスワードやトークンをそのまま打つ可能性があるため、打鍵数だけを記録する。
local function is_secret_mode(mode)
	local first = mode:sub(1, 1)
	return first == "i" or first == "R" or first == "s" or first == "S" or first == "\19"
end

local function record_key(key)
	local mode = vim.api.nvim_get_mode().mode
	if is_secret_mode(mode) then
		local last = keys.items[#keys.items]
		if type(last) == "table" and last.insert then
			last.insert = last.insert + 1
		else
			ring_push(keys, { insert = 1 })
		end
		return
	end
	ring_push(keys, vim.fn.keytrans(key))
end

-- リングバッファのキー列を 1 本の文字列に潰す
local function keys_to_string(items)
	local parts = {}
	for _, item in ipairs(items) do
		if type(item) == "table" then
			table.insert(parts, string.format("<insert x%d>", item.insert))
		else
			table.insert(parts, item)
		end
	end
	return table.concat(parts)
end

local function timestamp()
	return os.date("%Y-%m-%dT%H:%M:%S")
end

local LEVEL_NAMES = {
	[vim.log.levels.TRACE] = "TRACE",
	[vim.log.levels.DEBUG] = "DEBUG",
	[vim.log.levels.INFO] = "INFO",
	[vim.log.levels.WARN] = "WARN",
	[vim.log.levels.ERROR] = "ERROR",
}

-- 現在の編集状態のスナップショット。
-- notify は高速パスなので、失敗しうる API はすべて pcall で包む。
local function context()
	local ok, ctx = pcall(function()
		local win = vim.api.nvim_get_current_win()
		local buf = vim.api.nvim_win_get_buf(win)
		local cursor = vim.api.nvim_win_get_cursor(win)
		local name = vim.api.nvim_buf_get_name(buf)
		return {
			buf = name ~= "" and vim.fn.fnamemodify(name, ":~") or "[No Name]",
			ft = vim.bo[buf].filetype,
			cursor = { cursor[1], cursor[2] },
			mode = vim.api.nvim_get_mode().mode,
			cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~"),
		}
	end)
	return ok and ctx or {}
end

-- ─────────────────────────── 書き出し ───────────────────────────

local function rotate()
	local stat = vim.uv.fs_stat(LOG_FILE)
	if not stat or stat.size <= MAX_BYTES then
		return
	end
	-- 古い世代から順にずらす (.1 -> .2 が先、最後に本体 -> .1)
	for gen = MAX_GENERATIONS - 1, 1, -1 do
		local from = LOG_FILE .. "." .. gen
		if vim.uv.fs_stat(from) then
			vim.uv.fs_rename(from, LOG_FILE .. "." .. (gen + 1))
		end
	end
	vim.uv.fs_rename(LOG_FILE, LOG_FILE .. ".1")
end

local function append(record)
	local ok, encoded = pcall(vim.json.encode, record)
	if not ok then
		return
	end
	local f = io.open(LOG_FILE, "a")
	if not f then
		return
	end
	f:write(encoded, "\n")
	f:close()
end

-- VimLeave の v:errmsg は notify 経由で記録済みのものと重複しやすいので、
-- 直前に書いたメッセージを覚えておいて同一なら捨てる。
local last_msg = nil

-- 1 レコードを組み立てて追記する。source は捕捉経路 ("notify" / "v:errmsg")
function M.record(level, msg, source, traceback)
	if source == "v:errmsg" and msg == last_msg then
		return
	end
	last_msg = msg
	local ctx = context()
	append({
		ts = timestamp(),
		level = LEVEL_NAMES[level] or tostring(level),
		source = source,
		msg = msg,
		buf = ctx.buf,
		ft = ctx.ft,
		cursor = ctx.cursor,
		mode = ctx.mode,
		cwd = ctx.cwd,
		keys = keys_to_string(ring_snapshot(keys)),
		cmds = ring_snapshot(cmds),
		events = ring_snapshot(events),
		traceback = traceback,
	})
end

-- ─────────────────────────── ビューア ───────────────────────────

local function read_records()
	local f = io.open(LOG_FILE, "r")
	if not f then
		return {}
	end
	local records = {}
	for line in f:lines() do
		if line ~= "" then
			local ok, decoded = pcall(vim.json.decode, line)
			if ok and type(decoded) == "table" then
				table.insert(records, decoded)
			end
		end
	end
	f:close()
	return records
end

local function render(record)
	local lines = {
		string.format("[%s] %s  (%s)", record.ts or "?", record.level or "?", record.source or "?"),
	}
	for _, msg_line in ipairs(vim.split(tostring(record.msg or ""), "\n", { plain = true })) do
		table.insert(lines, "  " .. msg_line)
	end
	local cursor = record.cursor and string.format("%d:%d", record.cursor[1], record.cursor[2]) or "?"
	table.insert(lines, string.format("  buf: %s (%s) @ %s", record.buf or "?", record.ft or "", cursor))
	table.insert(lines, string.format("  cwd: %s  mode: %s", record.cwd or "?", record.mode or "?"))
	if record.keys and record.keys ~= "" then
		table.insert(lines, "  keys: " .. record.keys)
	end
	if record.cmds and #record.cmds > 0 then
		table.insert(lines, "  cmds: " .. table.concat(record.cmds, " | "))
	end
	if record.events and #record.events > 0 then
		table.insert(lines, "  events: " .. table.concat(record.events, " "))
	end
	if record.traceback and record.traceback ~= "" then
		table.insert(lines, "  traceback:")
		for _, tb_line in ipairs(vim.split(record.traceback, "\n", { plain = true })) do
			table.insert(lines, "    " .. vim.trim(tb_line))
		end
	end
	table.insert(lines, "")
	return lines
end

function M.open()
	local records = read_records()
	local lines = { "Neovim diagnostics log: " .. LOG_FILE, "" }
	if #records == 0 then
		table.insert(lines, "(記録なし)")
	else
		-- 新しいものから表示する
		local from = math.max(1, #records - VIEW_LIMIT + 1)
		for i = #records, from, -1 do
			vim.list_extend(lines, render(records[i]))
		end
		if from > 1 then
			table.insert(lines, string.format("... 古い %d 件は省略 (ファイルを直接参照)", from - 1))
		end
	end

	vim.cmd("tabnew")
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_set_name(buf, "nvim-diag.log")
end

function M.clear()
	os.remove(LOG_FILE)
	vim.notify("DiagLog: " .. LOG_FILE .. " を削除しました")
end

-- ──────────────────────────── setup ────────────────────────────

-- 他モジュールより前に呼ぶこと。起動中に発生した警告を取りこぼさないため。
function M.setup()
	vim.fn.mkdir(LOG_DIR, "p")
	rotate()

	-- LSP のログレベルは環境によって既定が揺れるので明示する
	pcall(function()
		vim.lsp.log.set_level(vim.log.levels.WARN)
	end)

	-- notify のラップ: WARN 以上のみ永続化する
	local original = vim.notify
	vim.notify = function(msg, level, opts)
		if (level or vim.log.levels.INFO) >= vim.log.levels.WARN then
			pcall(M.record, level, tostring(msg), "notify", debug.traceback("", 2))
		end
		return original(msg, level, opts)
	end

	-- キー入力のリングバッファ (insert 系では打鍵数のみ)
	local ns = vim.api.nvim_create_namespace("dotfiles_diaglog")
	vim.on_key(function(key, typed)
		pcall(record_key, (typed and typed ~= "") and typed or key)
	end, ns)

	local augroup = vim.api.nvim_create_augroup("dotfiles_diaglog", { clear = true })

	vim.api.nvim_create_autocmd("CmdlineLeave", {
		group = augroup,
		callback = function()
			local line = vim.fn.getcmdline()
			if line and line ~= "" then
				ring_push(cmds, vim.fn.getcmdtype() .. line)
			end
		end,
	})

	vim.api.nvim_create_autocmd(WATCHED_EVENTS, {
		group = augroup,
		callback = function(args)
			ring_push(events, args.event)
		end,
	})

	-- notify を通らない経路の取りこぼし対策。
	-- 直近のエラーメッセージ (v:errmsg) は終了時にしか確実には拾えない。
	vim.api.nvim_create_autocmd("VimLeave", {
		group = augroup,
		callback = function()
			if vim.v.errmsg and vim.v.errmsg ~= "" then
				pcall(M.record, vim.log.levels.ERROR, vim.v.errmsg, "v:errmsg")
			end
		end,
	})

	vim.api.nvim_create_user_command(
		"DotfilesLog",
		function()
			M.open()
		end,
		{ desc = "記録済みのエラー / 警告ログを新しいタブで表示 (操作コンテキスト付き)" }
	)

	vim.api.nvim_create_user_command("DotfilesLogClear", function()
		M.clear()
	end, { desc = "エラー / 警告ログのファイルを削除する" })
end

return M
