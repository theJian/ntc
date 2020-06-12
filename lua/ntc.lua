local fwdKey = '<plug>(NtcFwd)'
local bwdKey = '<plug>(NtcBwd)'
local cycKey = '<plug>(NtcCyc)'

local options = {
	no_mappings = false,
	auto_popup = false,
	popup_delay = 20,
	chain = {'curt', 'file'}
}

local function termcode(k)
	return vim.api.nvim_replace_termcodes(k, true, true, true)
end

local key_c_n = termcode('<c-n>')
local key_c_p = termcode('<c-p>')
local key_tab = termcode('<tab>')
local key_c_x_c_l = termcode('<c-x><c-l>')
local key_c_x_c_n = termcode('<c-x><c-n>')
local key_c_x_c_k = termcode('<c-x><c-k>')
local key_c_x_c_t = termcode('<c-x><c-t>')
local key_c_x_c_i = termcode('<c-x><c-i>')
local key_c_x_c_rbracket = termcode('<c-x><c-]>')
local key_c_x_c_f = termcode('<c-x><c-f>')
local key_c_x_c_d = termcode('<c-x><c-d>')
local key_c_x_c_v = termcode('<c-x><c-v>')
local key_c_x_c_u = termcode('<c-x><c-u>')
local key_c_x_c_o = termcode('<c-x><c-o>')
local key_c_x_s = termcode('<c-x>s')

local completion = {
	line = key_c_x_c_l,
	curt= key_c_x_c_n,
	dict = key_c_x_c_k,
	thes = key_c_x_c_t,
	incl = key_c_x_c_i,
	tags = key_c_x_c_rbracket,
	file = key_c_x_c_f,
	defn = key_c_x_c_d,
	vcmd = key_c_x_c_v,
	user = key_c_x_v_u,
	omni = key_c_x_c_o,
	spel = key_c_x_s,
	cmpl = key_c_n,
}

local function clear_timer(timer)
	if timer and not timer:is_closing() then
		timer:stop()
		timer:close()
	end
end

local function debounce(fn)
	local timer
	return function ()
		clear_timer(timer)
		timer = vim.loop.new_timer()
		timer:start(
			vim.b.options.popup_delay,
			0,
			function()
				clear_timer(timer)
				vim.schedule_wrap(fn)()
			end
		)
	end
end

local function set_expr_mapping(lhs, luaexpr)
	local expr = string.gsub(luaexpr, '"', "'")
	vim.api.nvim_buf_set_keymap('i', lhs, 'luaeval("' .. expr .. '")', { silent = true, expr = true, noremap = true })
end

local function set_key_mapping(lhs, rhs)
	vim.api.nvim_buf_set_keymap('i', lhs, rhs, { unique = true })
end

local c = 1
local function next_c(chain)
	return (c % #chain) + 1
end

local function ins_complete(new_c)
	local chain = vim.b.options.chain
	if new_c then
		c = new_c
	else
		c = next_c(chain)
	end

	if chain[c] == 'omni' then
		local omnifunc = vim.api.nvim_buf_get_option(0, 'omnifunc')
		if omnifunc == '' then
			c = next_c(chain)
		end
	end

	return completion[chain[c]] or ''
end

local function should_trigger_complete()
	if not string.find(vim.api.nvim_get_mode().mode, 'i') then
		return false
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	-- the start line index is zero based while the row index returnd by nvim_win_get_cursor
	-- is 1 based, so row index need to -1 to get the line where cursor is on.
	local line = unpack(vim.api.nvim_buf_get_lines(0, row - 1, row, false))
	local line_before_cursor = string.sub(line, 1, col)

	return vim.fn.match(line_before_cursor, '\\k$') >= 0
end

local function complete(dir)
	if vim.fn.pumvisible() == 0 then
		if should_trigger_complete() then
			return ins_complete(1)
		end
		return key_tab
	end

	if dir > 0 then
		return key_c_n
	else
		return key_c_p
	end
end

local function cycle()
	return ins_complete()
end

local function popup_immediately()
	if should_trigger_complete() then
		vim.api.nvim_input(ins_complete(1))
	end
end

local popup = debounce(popup_immediately)

local function setup(user_options)
	vim.b.options = vim.tbl_extend('keep', user_options or {}, options)
	set_expr_mapping(fwdKey, 'require("ntc").complete(1)')
	set_expr_mapping(bwdKey, 'require("ntc").complete(-1)')
	set_expr_mapping(cycKey, 'require("ntc").cycle()')

	if vim.b.options.auto_popup then
		vim.api.nvim_command('autocmd InsertCharPre * <buffer> noautocmd lua require"ntc".popup()')
	end

	if not vim.b.options.no_mappings then
		set_key_mapping('<tab>', fwdKey)
		set_key_mapping('<s-tab>', bwdKey)
		set_key_mapping('<c-space>', cycKey)
	end
end

return {
	complete = complete,
	cycle = cycle,
	popup = popup,
	setup = setup,
}
