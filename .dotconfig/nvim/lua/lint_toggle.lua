-- filetype 別 lint トグル
-- 実体は vim.diagnostic 表示の切り替え。LSP の publishDiagnostics と
-- nvim-lint の両方が対象。formatter (conform.nvim) には影響しない。
-- 状態は ft 単位で JSON に永続化される (Neovim 再起動後も維持)。

local M = {}

local STATE_FILE = vim.fn.stdpath("state") .. "/lint_disabled.json"

-- key = filetype, value = true (= 表示 OFF)
M.disabled = {}

local function load_state()
	local f = io.open(STATE_FILE, "r")
	if not f then
		return {}
	end
	local content = f:read("*a") or ""
	f:close()
	if content == "" then
		return {}
	end
	local ok, decoded = pcall(vim.json.decode, content)
	if not ok or type(decoded) ~= "table" then
		return {}
	end
	local result = {}
	for _, ft in ipairs(decoded) do
		if type(ft) == "string" then
			result[ft] = true
		end
	end
	return result
end

local function save_state()
	local arr = {}
	for ft in pairs(M.disabled) do
		table.insert(arr, ft)
	end
	table.sort(arr)
	local f = io.open(STATE_FILE, "w")
	if not f then
		vim.notify("LintToggle: failed to write " .. STATE_FILE, vim.log.levels.WARN)
		return
	end
	f:write(vim.json.encode(arr))
	f:close()
end

local function apply_to_buffers_of(ft, enabled)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == ft then
			vim.diagnostic.enable(enabled, { bufnr = buf })
		end
	end
end

function M.toggle()
	local ft = vim.bo.filetype
	if ft == "" then
		vim.notify("LintToggle: filetype が判定できません", vim.log.levels.WARN)
		return
	end
	if M.disabled[ft] then
		M.disabled[ft] = nil
		apply_to_buffers_of(ft, true)
		vim.notify(string.format("Lint [%s]: ON", ft))
	else
		M.disabled[ft] = true
		apply_to_buffers_of(ft, false)
		vim.notify(string.format("Lint [%s]: OFF", ft))
	end
	save_state()
end

function M.setup()
	M.disabled = load_state()

	local augroup = vim.api.nvim_create_augroup("dotfiles_lint_toggle", { clear = true })
	-- filetype 切替後 (例: `:set ft=...` でバッファの ft が変わったケース) も
	-- 新しい ft の状態に追従させるため、enabled / disabled の両方を明示的に反映する。
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		callback = function(args)
			local ft = vim.bo[args.buf].filetype
			vim.diagnostic.enable(not M.disabled[ft], { bufnr = args.buf })
		end,
	})

	vim.api.nvim_create_user_command("LintToggle", function()
		M.toggle()
	end, { desc = "現バッファの filetype の lint 表示を on/off (ft ごとに永続化)" })
end

return M
