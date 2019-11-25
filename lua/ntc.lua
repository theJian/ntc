local fwdKey = '<plug>(NtcFwd)'
local bwdKey = '<plug>(NtcBwd)'

local options = {
	no_mappings = false
}

local function config(user_options)
	options = vim.tbl_extend('force', options, user_options)
end

local function set_expr_mapping(lhs, luaexpr)
	local expr = string.gsub(luaexpr, '"', "'")
	vim.api.nvim_set_keymap('i', lhs, 'luaeval("' .. expr .. '")', { silent = true, expr = true, noremap = true })
end

local function set_key_mapping(lhs, rhs)
	vim.api.nvim_set_keymap('i', lhs, rhs, { unique = true })
end

local function termcode(k)
	return vim.api.nvim_replace_termcodes(k, true, true, true)
end

local function ins_complete(dir)
	return termcode('<c-n>')
end

local function complete(dir)
	if vim.api.nvim_call_function('pumvisible', {}) == 0 then
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		-- the start line index is zero based while the row index returnd by nvim_win_get_cursor
		-- is 1 based, so row index need to -1 to get the line where cursor is on.
		local line = unpack(vim.api.nvim_buf_get_lines(0, row - 1, row, false))
		local solidline = vim.trim(string.sub(line, col, col))
		if #solidline == 0 then
			return termcode('<tab>')
		end

		return ins_complete(dir)
	end

	if dir > 0 then
		return termcode("<c-n>")
	else
		return termcode("<c-p>")
	end
end

local function init()
	set_expr_mapping(fwdKey, 'require("ntc").complete(1)')
	set_expr_mapping(bwdKey, 'require("ntc").complete(-1)')

	if not options.no_mappings then
		set_key_mapping('<tab>', fwdKey)
		set_key_mapping('<s-tab>', bwdKey)
	end
end

init()

return {
	config = config,
	complete = complete,
}
