-- filetype 別 format on save トグル
-- conform.nvim の保存時フォーマットのみが対象。<leader>lf などの
-- 明示的な手動フォーマットは影響を受けない (意図的に実行しているため)。
-- 状態は ft 単位で JSON に永続化される (Neovim 再起動後も維持)。

local M = {}

local STATE_FILE = vim.fn.stdpath("state") .. "/format_disabled.json"

-- key = filetype, value = true (= 保存時フォーマット OFF)
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
		vim.notify("FormatToggle: failed to write " .. STATE_FILE, vim.log.levels.WARN)
		return
	end
	f:write(vim.json.encode(arr))
	f:close()
end

-- conform.nvim の format_on_save から呼ばれる判定関数
function M.is_disabled(bufnr)
	local ft = vim.bo[bufnr or 0].filetype
	return ft ~= "" and M.disabled[ft] == true
end

function M.toggle()
	local ft = vim.bo.filetype
	if ft == "" then
		vim.notify("FormatToggle: filetype が判定できません", vim.log.levels.WARN)
		return
	end
	if M.disabled[ft] then
		M.disabled[ft] = nil
		vim.notify(string.format("Format on save [%s]: ON", ft))
	else
		M.disabled[ft] = true
		vim.notify(string.format("Format on save [%s]: OFF", ft))
	end
	save_state()
end

function M.setup()
	M.disabled = load_state()

	vim.api.nvim_create_user_command("FormatToggle", function()
		M.toggle()
	end, { desc = "現バッファの filetype の保存時フォーマットを on/off (ft ごとに永続化)" })
end

return M
