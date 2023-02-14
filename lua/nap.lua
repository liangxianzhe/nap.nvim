local M = {}

local _config = {}

-- Record the last navigation operation.
local _next = nil
local _prev = nil

-- Catch and print the error when executing the command.
local call = function(command)
	local ok, result = pcall(vim.cmd, command)
	if not ok then print(result) end
end

-- Execute either next or prev command based on parameter norp (next_or_prev).
local exec = function(next, prev, norp)
	-- Save both command so that we can jump forth and back.
	_next = next
	_prev = prev
	if norp then call(next) else call(prev) end
end

-- Execute the last navigation operation based on parameter norp (next_or_prev).
local exec_last = function(norp)
	if norp and _next ~= nil then
		call(_next)
	elseif not norp and _prev ~= nil then
		call(_prev)
	else
		vim.notify(string.format('[nap.nvim] %s stack is empty.', norp and 'Next' or 'Previous'), vim.log.levels.WARN)
	end
end

-- Add keymaps to navigate between Next And Previous.
function M.nap(key, next, prev, next_desc, prev_desc)
	local next_prefix = _config.next_prefix or '<c-n>'
	local prev_prefix = _config.prev_prefix or '<c-p>'
	local next_key = next_prefix .. key
	local prev_key = prev_prefix .. key
	vim.keymap.set("n", next_key, function() exec(next, prev, true) end, { desc = next_desc })
	vim.keymap.set("n", prev_key, function() exec(next, prev, false) end, { desc = prev_desc })
end

-- Setup.
function M.setup(config)
	_config = config or {}
	local next_repeat = _config.next_repeat or '<c-n>'
	local prev_repeat = _config.prev_repeat or '<c-p>'
	vim.keymap.set("n", next_repeat, function() exec_last(true) end, { desc = "Repeat next" })
	vim.keymap.set("n", prev_repeat, function() exec_last(false) end, { desc = "Repeat previous" })

	if next_repeat == '<cr>' or prev_repeat == '<cr>' then
		-- If <cr> is used to repeat jump, it should still open the item in quickfix window
		vim.api.nvim_create_autocmd(
			"FileType", {
			pattern = { "qf" },
			command = [[nnoremap <buffer> <CR> <CR>]]
		})
	end

	M.nap("a", "tabnext", "tabprevious", "Next tab", "Previous tab")
	M.nap("A", "tablast", "tabfirst", "Last tab", "First tab")

	M.nap("b", "bnext", "bprevious", "Next buffer", "Previous buffer")
	M.nap("B", "blast", "bfist", "Last buffer", "First buffer")

	M.nap("d", "lua vim.diagnostic.goto_next()", "lua vim.diagnostic.goto_prev()", "Next diagnostic", "Previous diagnostic")

	M.nap("l", "lnext", "lprevious", "Next item in location list", "Previous item in location list")
	M.nap("L", "llast", "lfist", "Last item in location list", "First item in location list")
	M.nap("<C-l", "lnfile", "lpfile", "Next item in different file in location list",
		"Previous item in different file in location list")

	M.nap("q", "cnext", "cprevious", "Next item in quickfix list", "Previous item in quickfix list")
	M.nap("Q", "clast", "cfist", "Last item in quickfix list", "First item in quickfix list")
	M.nap("<C-q", "cnfile", "cpfile", "Next item in different file in quickfix list",
		"Previous item in different file in quickfix list")

	M.nap("s", "normal ]s", "normal [s", "Next spell error", "Previous spell error")

	M.nap("t", "tnext", "tprevious", "Next tag", "Previous tag")
	M.nap("T", "tlast", "tfist", "Last tag", "First tag")
	M.nap("<C-t", "ptnext", "ptprevious", "Next tag in previous window", "Previous tag in previous window")
end

return M
