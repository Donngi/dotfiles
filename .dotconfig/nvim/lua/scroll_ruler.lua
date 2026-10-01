-- 右端の概要ルーラー付きスクロールバー (VSCode 相当)
--
-- 編集ウィンドウ (owner) ごとに、その右隣へ幅 1 の専用分割ウィンドウ (ruler) を置き、
-- ruler のバッファにトラック / サム / git・診断・カーソルのマークを描く。
--
-- なぜプラグインでも extmark でもなく分割ウィンドウなのか
-- ------------------------------------------------------
-- ターミナルの最右列には「テキスト」か「バー」のどちらか一方しか置けない。
--   - フローティングウィンドウを重ねる方式 (satellite.nvim / nvim-scrollview):
--     Neovim の compositor (src/nvim/ui_compositor.c) の winblend 透過判定が
--       thru = (フロート側のセルが半角スペース) && bg_line[i] != NUL
--     で、NUL は全角文字の 2 セル目を指すため、フロートの左端が全角を分断すると
--     透過が成立せず全角が割れる。端末幅のパリティ次第で 1 画面 10 セル近く壊れた。
--   - extmark の virt_text_pos = "right_align" で描く方式 (nvim-scrollbar):
--     割れはしないが、表示行が最右列まで埋まっていると行末の文字を折り返さずに
--     切り捨てる (実測: 画面内の文字数 325 → 321。「設定の追加」が「設定の追」に)。
-- 分割ウィンドウなら本文ウィンドウ自体が物理的に狭くなるので、テキストとバーが
-- 列を奪い合わない。全角は割れず、文字も消えず、wrap は通常どおり折り返される。
-- 代償は 2 列 (ruler 1 列 + 区切り 1 列。区切りは背景色で塗って見えなくする)。
--
-- 分割ウィンドウ方式の落とし穴と、このモジュールでの対処
-- ------------------------------------------------------
--   - <C-w>l / <C-w>w で ruler に入ってしまう (split は focusable=false にできない)
--       → WinEnter で検知し、直前のキー操作の方向に応じて隣のウィンドウへ通り抜ける。
--         マウスクリックで入った場合は、クリック位置に比例した行へ owner をジャンプさせる
--   - :only で ruler も閉じられる → WinClosed で再構成して作り直す
--   - :q で owner を閉じると ruler だけが残り nvim が終了しない
--       → QuitPre で先に ruler を閉じる。:close など QuitPre が来ない経路は WinClosed で
--         孤立した ruler を閉じ、それが最後のウィンドウなら通常ウィンドウに戻す
--   - :vsplit / :split / aerial などで ruler が owner の隣から外れる
--       → 位置と高さを検査し、ずれていたら閉じて owner の右に作り直す
--   - ruler の開閉で equalalways が働き、手動で調整したウィンドウ幅が均等に戻される
--     (実測: 70/25 → 49/46)。equalalways を一時的に切るのも不可で、OFF→ON に戻した
--     瞬間に全ウィンドウが均等化される。
--       → 開閉の間だけ eadirection を "ver" にする。ruler は常に縦分割なので横方向の
--         均等化だけが止まり、幅も高さも保たれる (実測: 70/25・高さ 8 行のまま)
--   - laststatus=2 だと ruler にもステータス行が出る
--       → statusline を空白にし、owner がカレントなら StatusLine、それ以外は
--         StatusLineNC の色で塗って owner のステータス行と地続きに見せる
--   - コマンドラインウィンドウ (q:) の中ではウィンドウを開閉できない (E11) → 何もしない

local M = {}

local api = vim.api
local ns = api.nvim_create_namespace("dotfiles_scroll_ruler")

local config = {
	-- サムの最小高。比例計算だけだと長いファイルで 1 行になるため下限を設ける
	-- (VSCode も同様に最小サイズを強制している)。
	min_thumb = 3,
	-- これより狭いウィンドウには ruler を付けない (2 列を奪うと本文が読めなくなるため)
	min_owner_width = 30,
	excluded_filetypes = {
		"NvimTree",
		"aerial",
		"toggleterm",
		"trouble",
		"lazy",
		"TelescopePrompt",
		"help",
		"qf",
		"blink-cmp-menu",
		"noice",
		"prompt",
	},
	excluded_buftypes = {
		"terminal",
		"nofile",
		"quickfix",
		"prompt",
		"help",
	},
	-- 描画 1 回が軽いので 30ms (≒33fps) でも負荷にならない
	throttle_ms = 30,
}

-- マークの優先度。同じ行に複数来たときは数字が大きい方を描く。
local PRIORITY = {
	track = 0,
	thumb = 1,
	git = 2,
	hint = 3,
	info = 4,
	warn = 5,
	error = 6,
	cursor = 7,
}

local MARKS = {
	blank = { char = " ", hl = "ScrollRulerBlank" },
	track = { char = " ", hl = "ScrollRulerTrack" },
	thumb = { char = " ", hl = "ScrollRulerThumb" },
	git_add = { char = "│", hl = "ScrollRulerGitAdd" },
	git_change = { char = "│", hl = "ScrollRulerGitChange" },
	git_delete = { char = "_", hl = "ScrollRulerGitDelete" },
	error = { char = "●", hl = "ScrollRulerError" },
	warn = { char = "●", hl = "ScrollRulerWarn" },
	info = { char = "●", hl = "ScrollRulerInfo" },
	hint = { char = "●", hl = "ScrollRulerHint" },
	cursor = { char = "▸", hl = "ScrollRulerCursor" },
}

local enabled = true

-- ---------------------------------------------------------------------------
-- ハイライト
-- ---------------------------------------------------------------------------

-- 配色は VSCode に合わせる: トラック (溝) は本文と同じ背景で見せず、サムだけを
-- VSCode の scrollbarSlider.background (#79797966 = #797979 の不透明度 40%) で描く。
-- ターミナルには透過が無いので、その色を本文の背景色に合成した結果を使う
-- (#1f1f1f の上なら #434343)。背景色から計算するのでカラースキームを変えても破綻しない。
-- ColorScheme で張り直す。default = true なので好みで上書きできる。
local function set_highlights()
	local function get(name)
		return api.nvim_get_hl(0, { name = name, link = false }) or {}
	end
	local function bg_of(name, fallback)
		return get(name).bg or fallback
	end
	local function fg_of(name, fallback)
		local hl = get(name)
		return hl.fg or hl.bg or fallback
	end

	-- fg を alpha の不透明度で bg に重ねた色
	local function blend(fg, bg, alpha)
		local function ch(c, shift)
			return math.floor(bit.band(bit.rshift(c, shift), 0xff))
		end
		local out = 0
		for _, shift in ipairs({ 16, 8, 0 }) do
			local v = math.floor(ch(fg, shift) * alpha + ch(bg, shift) * (1 - alpha) + 0.5)
			out = out + bit.lshift(v, shift)
		end
		return out
	end

	local normal_bg = bg_of("Normal", 0x1f1f1f)
	local normal_fg = fg_of("Normal", 0xd4d4d4)
	local track_bg = normal_bg
	local thumb_bg = blend(0x797979, normal_bg, 0x66 / 0xff)

	local defs = {
		-- 全行が画面に収まっているときの空の ruler。本文と同じ背景で余白に見せる
		ScrollRulerBlank = { bg = normal_bg },
		-- owner と ruler の間の区切り線を見えなくする
		ScrollRulerSep = { fg = normal_bg, bg = normal_bg },
		ScrollRulerTrack = { bg = track_bg },
		ScrollRulerThumb = { bg = thumb_bg },
		ScrollRulerGitAdd = { fg = fg_of("GitSignsAdd", 0x587c0c), bg = track_bg },
		ScrollRulerGitChange = { fg = fg_of("GitSignsChange", 0x0c7d9d), bg = track_bg },
		ScrollRulerGitDelete = { fg = fg_of("GitSignsDelete", 0x94151b), bg = track_bg },
		ScrollRulerError = { fg = fg_of("DiagnosticError", 0xf44747), bg = track_bg },
		ScrollRulerWarn = { fg = fg_of("DiagnosticWarn", 0xff8800), bg = track_bg },
		ScrollRulerInfo = { fg = fg_of("DiagnosticInfo", 0x4fc1ff), bg = track_bg },
		ScrollRulerHint = { fg = fg_of("DiagnosticHint", 0xb267e6), bg = track_bg },
		-- カーソルは必ず可視範囲 = サムの中にあるので、サムの暗いグレーの上で
		-- 読めるよう本文の文字色を使う。
		ScrollRulerCursor = { fg = normal_fg, bg = thumb_bg },
	}
	for name, def in pairs(defs) do
		def.default = true
		api.nvim_set_hl(0, name, def)
	end

	-- マークがサムの上に乗る場合、背景をトラック色のままにするとサムに暗い
	-- 切り欠きができる。背景だけサム色に差し替えた <name>OnThumb を用意する。
	for name, def in pairs(defs) do
		if def.fg and name ~= "ScrollRulerSep" then
			api.nvim_set_hl(0, name .. "OnThumb", { fg = def.fg, bg = thumb_bg, default = true })
		end
	end
end

-- ---------------------------------------------------------------------------
-- ウィンドウの判定
-- ---------------------------------------------------------------------------

local function valid(win)
	return win ~= nil and win ~= 0 and api.nvim_win_is_valid(win)
end

local function is_ruler(win)
	return valid(win) and vim.w[win].scroll_ruler_owner ~= nil
end

local function ruler_of(owner)
	if not valid(owner) then
		return nil
	end
	local r = vim.w[owner].scroll_ruler_win
	if valid(r) then
		return r
	end
	return nil
end

-- owner (ruler を付ける編集ウィンドウ) になれるか
local function is_owner_candidate(win)
	if not valid(win) or is_ruler(win) then
		return false
	end
	if api.nvim_win_get_config(win).relative ~= "" then
		return false -- フローティングウィンドウ
	end
	if vim.wo[win].previewwindow then
		return false
	end
	local buf = api.nvim_win_get_buf(win)
	if vim.tbl_contains(config.excluded_filetypes, vim.bo[buf].filetype) then
		return false
	end
	if vim.tbl_contains(config.excluded_buftypes, vim.bo[buf].buftype) then
		return false
	end
	-- ruler が付いている間は 2 列狭くなっているので、その分を足して判定する
	-- (足さないと「付ける → 狭くなる → 外す → 広くなる → 付ける」を繰り返す)
	local width = api.nvim_win_get_width(win) + (ruler_of(win) and 2 or 0)
	return width >= config.min_owner_width
end

-- ruler が owner の右隣に、同じ高さ・幅 1 で並んでいるか
local function ruler_in_place(owner, r)
	if api.nvim_win_get_tabpage(r) ~= api.nvim_win_get_tabpage(owner) then
		return false
	end
	local op, rp = vim.fn.win_screenpos(owner), vim.fn.win_screenpos(r)
	return rp[1] == op[1]
		and rp[2] == op[2] + api.nvim_win_get_width(owner) + 1
		and api.nvim_win_get_height(r) == api.nvim_win_get_height(owner)
end

-- ---------------------------------------------------------------------------
-- owner 側のウィンドウオプション (区切り線を消す) の付け外し
-- ---------------------------------------------------------------------------

local function get_local(win, name)
	return api.nvim_get_option_value(name, { win = win, scope = "local" })
end

local function set_local(win, name, value)
	api.nvim_set_option_value(name, value, { win = win, scope = "local" })
end

-- "a:1,b:2" 形式のオプション値で key だけを差し替える
local function with_item(value, key, item)
	local items = {}
	for part in vim.gsplit(value, ",", { plain = true, trimempty = true }) do
		if not vim.startswith(part, key .. ":") then
			items[#items + 1] = part
		end
	end
	items[#items + 1] = key .. ":" .. item
	return table.concat(items, ",")
end

-- 区切り線は「左側のウィンドウ」が描くので、owner の fillchars / winhighlight を
-- 書き換える。元の値を退避しておき、ruler を外すときに戻す。
local function attach_owner(owner)
	if vim.w[owner].scroll_ruler_saved then
		return
	end
	local saved = {
		fillchars = get_local(owner, "fillchars"),
		winhighlight = get_local(owner, "winhighlight"),
	}
	vim.w[owner].scroll_ruler_saved = saved
	local fill = saved.fillchars ~= "" and saved.fillchars or vim.go.fillchars
	set_local(owner, "fillchars", with_item(fill, "vert", " "))
	set_local(owner, "winhighlight", with_item(saved.winhighlight, "WinSeparator", "ScrollRulerSep"))
end

local function detach_owner(owner)
	if not valid(owner) then
		return
	end
	local saved = vim.w[owner].scroll_ruler_saved
	if saved then
		set_local(owner, "fillchars", saved.fillchars)
		set_local(owner, "winhighlight", saved.winhighlight)
		vim.w[owner].scroll_ruler_saved = nil
	end
	vim.w[owner].scroll_ruler_win = nil
end

-- ---------------------------------------------------------------------------
-- ruler ウィンドウの生成・破棄
-- ---------------------------------------------------------------------------

-- ruler 用に変更する window-local オプション。通常ウィンドウへ戻すときは
-- グローバル値で上書きする。
local RULER_WIN_OPTS = {
	number = false,
	relativenumber = false,
	signcolumn = "no",
	foldcolumn = "0",
	statuscolumn = "",
	colorcolumn = "",
	wrap = false,
	cursorline = false,
	cursorcolumn = false,
	list = false,
	spell = false,
	scrolloff = 0,
	sidescrolloff = 0,
	winfixwidth = true,
	winfixbuf = true,
	fillchars = "eob: ",
	statusline = " ",
	winhighlight = "",
}

local function create_ruler(owner)
	local buf = api.nvim_create_buf(false, true) -- unlisted な scratch (bufferline に出ない)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].undolevels = -1
	vim.bo[buf].filetype = "scrollruler"
	vim.bo[buf].modifiable = false

	local ok, r = pcall(api.nvim_open_win, buf, false, { split = "right", win = owner, width = 1 })
	if not ok then
		pcall(api.nvim_buf_delete, buf, { force = true })
		return nil
	end
	for name, value in pairs(RULER_WIN_OPTS) do
		set_local(r, name, value)
	end
	vim.w[r].scroll_ruler_owner = owner
	vim.w[owner].scroll_ruler_win = r
	attach_owner(owner)
	return r
end

-- 最後の 1 枚になってしまった ruler を閉じられないとき、普通の編集ウィンドウに戻す。
-- owner が最後に表示していたバッファを出すので、ユーザーから見ると owner を
-- 閉じる操作が無かったように見える。
local function convert_to_normal(r)
	local last_buf = vim.w[r].scroll_ruler_last_buf
	set_local(r, "winfixbuf", false)
	if not (last_buf and api.nvim_buf_is_valid(last_buf)) then
		last_buf = api.nvim_create_buf(true, false)
	end
	api.nvim_win_set_buf(r, last_buf)
	for name in pairs(RULER_WIN_OPTS) do
		set_local(r, name, api.nvim_get_option_value(name, { scope = "global" }))
	end
	vim.w[r].scroll_ruler_owner = nil
	vim.w[r].scroll_ruler_sig = nil
	vim.w[r].scroll_ruler_last_buf = nil
end

local function close_ruler(r)
	if not valid(r) then
		return
	end
	local owner = vim.w[r].scroll_ruler_owner
	if valid(owner) and vim.w[owner].scroll_ruler_win == r then
		detach_owner(owner)
	end
	if not pcall(api.nvim_win_close, r, true) then
		convert_to_normal(r)
	end
end

-- ruler の開閉で他のウィンドウ幅が均等化されないようにする。
-- eadirection の変更自体には副作用が無い (equalalways と違い、戻しても均等化は走らない)。
local function keep_sizes(fn)
	local ead = vim.o.eadirection
	vim.o.eadirection = "ver"
	local ok, err = pcall(fn)
	vim.o.eadirection = ead
	if not ok then
		error(err, 0)
	end
end

-- ---------------------------------------------------------------------------
-- 再構成: 全 owner に正しい位置の ruler がある状態にする
-- ---------------------------------------------------------------------------

local reconciling = false

local function reconcile()
	if reconciling or vim.fn.getcmdwintype() ~= "" then
		return
	end
	reconciling = true

	local ok, err = pcall(keep_sizes, function()
		-- 1) 孤立・ずれた ruler を閉じる
		for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
			if is_ruler(w) then
				local owner = vim.w[w].scroll_ruler_owner
				local keep = enabled
					and valid(owner)
					and vim.w[owner].scroll_ruler_win == w
					and is_owner_candidate(owner)
					and ruler_in_place(owner, w)
				if not keep then
					close_ruler(w)
				elseif api.nvim_win_get_width(w) ~= 1 then
					api.nvim_win_set_width(w, 1)
				end
			end
		end

		-- 2) ruler が必要なウィンドウに作る / 不要になったウィンドウから外す
		for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
			if valid(w) and not is_ruler(w) then
				if enabled and is_owner_candidate(w) then
					if not ruler_of(w) then
						create_ruler(w)
					end
				elseif vim.w[w].scroll_ruler_saved or vim.w[w].scroll_ruler_win then
					local r = ruler_of(w)
					if r then
						close_ruler(r)
					else
						detach_owner(w)
					end
				end
			end
		end
	end)

	reconciling = false
	if not ok then
		vim.notify("scroll_ruler: " .. tostring(err), vim.log.levels.ERROR)
	end
end

-- ---------------------------------------------------------------------------
-- 描画
-- ---------------------------------------------------------------------------

-- owner の表示状態から、ruler の各行 (1..height) に描くマークを決める
local function compute_rows(owner, height)
	local buf = api.nvim_win_get_buf(owner)
	local total = api.nvim_buf_line_count(buf)
	local info = vim.fn.getwininfo(owner)[1]
	local rows = {}

	-- 全行が収まっているときはバーを出さない (余白に見せる)
	if info.topline <= 1 and info.botline >= total then
		for row = 1, height do
			rows[row] = { kind = "blank" }
		end
		return rows
	end

	local function to_row(lnum)
		if total <= 1 or height <= 1 then
			return 1
		end
		local r = math.floor((lnum - 1) / (total - 1) * (height - 1) + 0.5) + 1
		return math.min(math.max(r, 1), height)
	end

	local function put(row, kind, prio)
		if row < 1 or row > height then
			return
		end
		local cur = rows[row]
		if cur == nil or prio >= cur.prio then
			rows[row] = { kind = kind, prio = prio }
		end
	end

	for row = 1, height do
		put(row, "track", PRIORITY.track)
	end

	-- サム: 見えている範囲を比例配分し、min_thumb を下限にする
	local visible = info.botline - info.topline + 1
	local thumb_h = math.max(config.min_thumb, math.floor(visible / total * height + 0.5))
	thumb_h = math.min(thumb_h, height)
	local thumb_top = to_row(info.topline)
	if info.botline >= total then
		thumb_top = height - thumb_h + 1 -- 末尾が見えているときはサムを下端に揃える
	end
	thumb_top = math.min(math.max(thumb_top, 1), height - thumb_h + 1)
	local on_thumb = {}
	for row = thumb_top, thumb_top + thumb_h - 1 do
		put(row, "thumb", PRIORITY.thumb)
		on_thumb[row] = true
	end

	-- git の変更箇所
	local ok, gs = pcall(require, "gitsigns")
	if ok and gs.get_hunks then
		for _, hunk in ipairs(gs.get_hunks(buf) or {}) do
			local kind = "git_change"
			if hunk.type == "add" then
				kind = "git_add"
			elseif hunk.type == "delete" then
				kind = "git_delete"
			end
			local first = math.max(hunk.added.start, 1)
			local last = first + math.max(hunk.added.count, 1) - 1
			for row = to_row(first), to_row(last) do
				put(row, kind, PRIORITY.git)
			end
		end
	end

	-- LSP 診断
	local severity_kind = {
		[vim.diagnostic.severity.ERROR] = "error",
		[vim.diagnostic.severity.WARN] = "warn",
		[vim.diagnostic.severity.INFO] = "info",
		[vim.diagnostic.severity.HINT] = "hint",
	}
	for _, d in ipairs(vim.diagnostic.get(buf)) do
		local kind = severity_kind[d.severity]
		if kind then
			put(to_row(d.lnum + 1), kind, PRIORITY[kind])
		end
	end

	-- カーソル位置
	put(to_row(api.nvim_win_get_cursor(owner)[1]), "cursor", PRIORITY.cursor)

	for row, mark in pairs(rows) do
		mark.on_thumb = on_thumb[row] or false
	end
	return rows
end

local function render_ruler(owner, r)
	local height = api.nvim_win_get_height(r)
	if height < 1 then
		return
	end
	local rows = compute_rows(owner, height)
	local is_current = api.nvim_get_current_win() == owner

	local chars, hls = {}, {}
	for row = 1, height do
		local mark = rows[row] or { kind = "track" }
		local spec = MARKS[mark.kind]
		local hl = spec.hl
		if mark.on_thumb and mark.kind ~= "thumb" and mark.kind ~= "track" then
			hl = hl .. "OnThumb"
		end
		chars[row] = spec.char
		hls[row] = hl
	end

	-- 前回と同じ内容なら何もしない (スクロール中の無駄な再描画を減らす)
	local sig = table.concat(chars) .. "|" .. table.concat(hls, ",") .. "|" .. tostring(is_current)
	if vim.w[r].scroll_ruler_sig == sig then
		return
	end
	vim.w[r].scroll_ruler_sig = sig
	vim.w[r].scroll_ruler_last_buf = api.nvim_win_get_buf(owner)

	local rbuf = api.nvim_win_get_buf(r)
	vim.bo[rbuf].modifiable = true
	api.nvim_buf_set_lines(rbuf, 0, -1, false, chars)
	vim.bo[rbuf].modifiable = false
	api.nvim_buf_clear_namespace(rbuf, ns, 0, -1)
	for row = 1, height do
		api.nvim_buf_set_extmark(rbuf, ns, row - 1, 0, { line_hl_group = hls[row] })
	end
	-- ruler 自体はスクロールさせない
	api.nvim_win_call(r, function()
		vim.fn.winrestview({ topline = 1, lnum = 1, col = 0 })
	end)

	-- ステータス行のセル: owner がカレントなら StatusLine 色にして地続きに見せる。
	-- ruler 自身は決してカレントにならないので、常に StatusLineNC が使われる。
	local status = is_current and "StatusLine" or "StatusLineNC"
	set_local(
		r,
		"winhighlight",
		"Normal:ScrollRulerTrack,EndOfBuffer:ScrollRulerTrack,StatusLineNC:" .. status .. ",StatusLine:" .. status
	)
end

function M.render()
	if not enabled then
		return
	end
	for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
		local r = ruler_of(w)
		if r and not is_ruler(w) then
			render_ruler(w, r)
		end
	end
end

-- ---------------------------------------------------------------------------
-- ruler に入ってしまったときの通り抜け
-- ---------------------------------------------------------------------------

-- 直前に打たれたキーを 2 つだけ覚えておき、ruler に入った手段を推定する
local recent_keys = { "", "" }

local function entered_by()
	local a, b = recent_keys[1], recent_keys[2]
	if b:find("Mouse") or b:find("Release") or b:find("Drag") then
		return "mouse"
	end
	if a == "<C-W>" then
		if b == "w" or b == "<C-W>" then
			return "next"
		elseif b == "W" then
			return "prev"
		elseif b == "l" or b == "<Right>" or b == "<C-L>" then
			return "right"
		end
	end
	return "other"
end

local function bounce(r, prev)
	local owner = vim.w[r].scroll_ruler_owner
	local how = entered_by()

	vim.schedule(function()
		if api.nvim_get_current_win() ~= r then
			return
		end
		if not valid(owner) then
			reconcile()
			return
		end

		-- クリック: クリック位置に比例した行へ owner を移動 (VSCode のスクロールバーと同じ)
		if how == "mouse" then
			local mp = vim.fn.getmousepos()
			local height = api.nvim_win_get_height(r)
			local total = api.nvim_buf_line_count(api.nvim_win_get_buf(owner))
			local row = mp.winid == r and mp.winrow or 1
			local lnum = height <= 1 and 1 or math.floor((row - 1) / (height - 1) * (total - 1) + 0.5) + 1
			api.nvim_set_current_win(owner)
			api.nvim_win_set_cursor(owner, { math.min(math.max(lnum, 1), total), 0 })
			vim.cmd("normal! zz")
			return
		end

		-- キーボード: ruler が無かったら着いていたはずのウィンドウへ通り抜ける
		local target = owner
		if how == "right" then
			local right = vim.fn.win_getid(vim.fn.winnr("l"))
			if right ~= 0 and right ~= r and not is_ruler(right) then
				target = right
			end
		elseif how == "next" or how == "prev" then
			local wins = api.nvim_tabpage_list_wins(0)
			local idx
			for i, w in ipairs(wins) do
				if w == r then
					idx = i
				end
			end
			local step = how == "next" and 1 or -1
			for k = 1, #wins do
				local w = wins[((idx - 1 + step * k) % #wins) + 1]
				if not is_ruler(w) then
					target = w
					break
				end
			end
		end

		-- # (直前のウィンドウ) を「ruler に入る前にいたウィンドウ」に保つ。
		-- そうしないと <C-w>p や nvim-tree の「直前のウィンドウで開く」が ruler を指す。
		if valid(prev) and prev ~= target and not is_ruler(prev) then
			vim.cmd("noautocmd call win_gotoid(" .. prev .. ")")
		end
		api.nvim_set_current_win(target)
	end)
end

-- ---------------------------------------------------------------------------
-- スロットル
-- ---------------------------------------------------------------------------

-- debounce (イベントごとにタイマーを張り直す) にしてはいけない。neoscroll.nvim の
-- スムーススクロール中は WinScrolled がフレームごとに飛ぶため、debounce だと
-- アニメーションが終わるまで一度も描画されずバーが最後に飛ぶ = がたついて見える。
-- leading edge で即座に描き、クールダウン中のイベントは末尾で 1 回にまとめる。
local last_render = 0
local pending_timer = nil
local render_scheduled = false

local function render_soon()
	if render_scheduled then
		return
	end
	render_scheduled = true
	last_render = vim.uv.now()
	vim.schedule(function()
		render_scheduled = false
		local ok, err = pcall(M.render)
		if not ok then
			vim.notify("scroll_ruler: " .. tostring(err), vim.log.levels.ERROR)
		end
	end)
end

local function throttled_render()
	local since = vim.uv.now() - last_render
	if since >= config.throttle_ms then
		render_soon()
		return
	end
	if pending_timer then
		return
	end
	local t = vim.uv.new_timer()
	pending_timer = t
	t:start(
		config.throttle_ms - since,
		0,
		vim.schedule_wrap(function()
			t:stop()
			if not t:is_closing() then
				t:close()
			end
			if pending_timer == t then
				pending_timer = nil
			end
			render_soon()
		end)
	)
end

-- レイアウト変化は連続して来るので 1 tick にまとめてから再構成する
local reconcile_scheduled = false
local function reconcile_soon()
	if reconcile_scheduled then
		return
	end
	reconcile_scheduled = true
	vim.schedule(function()
		reconcile_scheduled = false
		reconcile()
		render_soon()
	end)
end

-- ---------------------------------------------------------------------------
-- 有効 / 無効
-- ---------------------------------------------------------------------------

local function close_all()
	keep_sizes(function()
		for _, tab in ipairs(api.nvim_list_tabpages()) do
			for _, w in ipairs(api.nvim_tabpage_list_wins(tab)) do
				if is_ruler(w) then
					close_ruler(w)
				end
			end
		end
	end)
end

function M.enable()
	enabled = true
	reconcile()
	render_soon()
end

function M.disable()
	enabled = false
	close_all()
end

-- ---------------------------------------------------------------------------
-- setup
-- ---------------------------------------------------------------------------

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	set_highlights()

	local group = api.nvim_create_augroup("dotfiles_scroll_ruler", { clear = true })

	vim.on_key(function(_, typed)
		if typed and typed ~= "" then
			recent_keys[1] = recent_keys[2]
			recent_keys[2] = vim.fn.keytrans(typed)
		end
	end, ns)

	api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			set_highlights()
			for _, w in ipairs(api.nvim_list_wins()) do
				if is_ruler(w) then
					vim.w[w].scroll_ruler_sig = nil
				end
			end
			render_soon()
		end,
		desc = "スクロールルーラーのハイライトを張り直す",
	})

	-- レイアウトが変わりうるイベント → 再構成
	api.nvim_create_autocmd({ "WinNew", "WinClosed", "WinResized", "VimResized", "TabEnter", "BufWinEnter", "FileType" }, {
		group = group,
		callback = reconcile_soon,
		desc = "スクロールルーラーの配置を整える",
	})

	-- 表示内容が変わりうるイベント → 再描画
	api.nvim_create_autocmd({
		"WinScrolled",
		"CursorMoved",
		"CursorMovedI",
		"TextChanged",
		"TextChangedI",
		"DiagnosticChanged",
		"BufEnter",
	}, {
		group = group,
		callback = throttled_render,
		desc = "スクロールルーラーを再描画",
	})
	api.nvim_create_autocmd("User", {
		pattern = "GitSignsUpdate",
		group = group,
		callback = throttled_render,
		desc = "スクロールルーラーの git マークを更新",
	})

	-- ruler に入ったら通り抜ける。それ以外のウィンドウに入ったらステータス行の色を更新
	api.nvim_create_autocmd("WinEnter", {
		group = group,
		callback = function()
			local cur = api.nvim_get_current_win()
			if is_ruler(cur) then
				bounce(cur, vim.fn.win_getid(vim.fn.winnr("#")))
			else
				throttled_render()
			end
		end,
		desc = "スクロールルーラーに入ったら隣のウィンドウへ抜ける",
	})

	-- :q / :wq / ZZ で owner を閉じる前に ruler を閉じる。こうしないと owner が
	-- 最後の編集ウィンドウでも ruler が残るため nvim が終了しない。
	-- quit が中断された場合 (未保存など) に備えて、あとで再構成もかける。
	api.nvim_create_autocmd("QuitPre", {
		group = group,
		callback = function()
			local r = ruler_of(api.nvim_get_current_win())
			if r then
				reconciling = true
				pcall(keep_sizes, function()
					close_ruler(r)
				end)
				reconciling = false
			end
			reconcile_soon()
		end,
		desc = "終了前にスクロールルーラーを閉じる",
	})

	api.nvim_create_user_command("ScrollRulerToggle", function()
		if enabled then
			M.disable()
		else
			M.enable()
		end
		vim.notify("scroll ruler: " .. (enabled and "ON" or "OFF"))
	end, { desc = "右端のスクロールバーを on/off" })
	api.nvim_create_user_command("ScrollRulerShow", M.enable, { desc = "右端のスクロールバーを表示" })
	api.nvim_create_user_command("ScrollRulerHide", M.disable, { desc = "右端のスクロールバーを非表示" })

	if vim.v.vim_did_enter == 1 then
		reconcile_soon()
	else
		api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = reconcile_soon })
	end
end

return M
