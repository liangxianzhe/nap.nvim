local M = {}

local _config = {}

-- Command execution.

-- Record the last navigation operation.
local _next = nil
local _prev = nil

-- Catch and print the error when executing the command.
---@param command string|function Command to execute.
local call = function(command)
	local ok, result
	if type(command) == "string" then
		ok, result = pcall(vim.cmd, command)
	else
		ok, result = pcall(command)
	end
	if not ok then
		vim.notify(string.format(result), vim.log.levels.WARN, { title = "nap.nvim" })
	end
end

-- Execute either next or prev command based on parameter norp (next_or_prev).
---@param next string|function Command to jump next.
---@param prev string|function Command to jump prev.
---@param norp boolean Next or prev.
local exec = function(next, prev, norp)
	-- Save both command so that we can jump forth and back.
	_next = next
	_prev = prev
	if norp then call(next) else call(prev) end
end

-- Execute the last navigation operation based on parameter norp (next_or_prev).
---@param norp boolean Next or prev.
local exec_last = function(norp)
	if norp and _next ~= nil then
		call(_next)
	elseif not norp and _prev ~= nil then
		call(_prev)
	else
		vim.notify(
			string.format('[nap.nvim] [%s] Nothing to repeat.', norp and 'Next' or 'Previous'),
			vim.log.levels.INFO,
			{ title = "nap.nvim", icon = norp and '-->' or '<--' }
		)
	end
end

-- Add keymaps to navigate between Next And Previous.
---@param key string Operator key, usually is a single character.
---@param next string|function Command to jump next.
---@param prev string|function Command to jump next.
---@param next_desc string Description of jump next.
---@param prev_desc string Description of jump next.
function M.nap(key, next, prev, next_desc, prev_desc)
	local next_prefix = _config.next_prefix or '<c-n>'
	local prev_prefix = _config.prev_prefix or '<c-p>'
	local next_key = next_prefix .. key
	local prev_key = prev_prefix .. key
	vim.keymap.set("n", next_key, function() exec(next, prev, true) end, { desc = next_desc })
	vim.keymap.set("n", prev_key, function() exec(next, prev, false) end, { desc = prev_desc })
end

-- File operator.

-- Get directory containing the buffer, or cwd.
local get_dir_path = function()
	local cur_buf_path = vim.api.nvim_buf_get_name(0)
	return cur_buf_path ~= '' and vim.fn.fnamemodify(cur_buf_path, ':p:h') or vim.fn.getcwd()
end

-- Get files in directory.
-- @param dir_path string Directory path.
local get_files = function(dir_path)
	-- Compute sorted array of all files in target directory
	local dir_handle = vim.loop.fs_scandir(dir_path)
	if dir_handle == nil then return end
	local files_stream = function() return vim.loop.fs_scandir_next(dir_handle) end

	local files = {}
	for basename, fs_type in files_stream do
		if fs_type == 'file' then table.insert(files, basename) end
	end

	-- - Sort files ignoring case
	table.sort(files, function(x, y) return x:lower() < y:lower() end)

	return files
end

-- Find index of current buffer in files.
-- @param files table Table of file names.
local cur_file_index = function(files)
	local cur_basename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':t')
	local cur_basename_ind
	if cur_basename ~= '' then
		for i, f in ipairs(files) do
			if cur_basename == f then
				cur_basename_ind = i
				break
			end
		end
	end
	return cur_basename_ind
end

-- Jump to next file in the same directory with current buffer, sorted by name.
function M.next_file()
	local dir_path = get_dir_path()
	local files = get_files(dir_path)
	if files == nil then return end
	local index = cur_file_index(files)
	if index + 1 <= #files then
		local path_sep = package.config:sub(1, 1)
		local target_path = dir_path .. path_sep .. files[index + 1]
		vim.cmd('edit ' .. target_path)
	end
end

-- Jump to prev file in the same directory with current buffer, sorted by name.
function M.prev_file()
	local dir_path = get_dir_path()
	local files = get_files(dir_path)
	if files == nil then return end
	local index = cur_file_index(files)
	if index > 1 then
		local path_sep = package.config:sub(1, 1)
		local target_path = dir_path .. path_sep .. files[index - 1]
		vim.cmd('edit ' .. target_path)
	end
end

-- Jump to fist file in the same directory with current buffer, sorted by name.
function M.first_file()
	local dir_path = get_dir_path()
	local files = get_files(dir_path)
	if files == nil then return end
	local path_sep = package.config:sub(1, 1)
	local target_path = dir_path .. path_sep .. files[1]
	vim.cmd('edit ' .. target_path)
end

-- Jump to last file in the same directory with current buffer, sorted by name.
function M.last_file()
	local dir_path = get_dir_path()
	local files = get_files(dir_path)
	if files == nil then return end
	local path_sep = package.config:sub(1, 1)
	local target_path = dir_path .. path_sep .. files[#files]
	vim.cmd('edit ' .. target_path)
end

-- Setup.

---@param config table Config table.
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
	M.nap("B", "blast", "bfirst", "Last buffer", "First buffer")

	M.nap("c", "normal! g,", "normal! g;", "Next change-list item", "Previous change-list item")

	M.nap("d", vim.diagnostic.goto_next, vim.diagnostic.goto_prev, "Next diagnostic", "Previous diagnostic")

	M.nap("f", M.next_file, M.prev_file, "Next file", "Previous file")
	M.nap("F", M.last_file, M.first_file, "Last file", "First file")

	M.nap("j", "normal! <C-i>", "normal! <C-o>", "Next jump-list item", "Previous jump-list item")

	M.nap("l", "lnext", "lprevious", "Next item in location list", "Previous item in location list")
	M.nap("L", "llast", "lfist", "Last item in location list", "First item in location list")
	M.nap("<C-l>", "lnfile", "lpfile", "Next item in different file in location list",
		"Previous item in different file in location list")

	M.nap("q", "cnext", "cprevious", "Next item in quickfix list", "Previous item in quickfix list")
	M.nap("Q", "clast", "cfirst", "Last item in quickfix list", "First item in quickfix list")
	M.nap("<C-q>", "cnfile", "cpfile", "Next item in different file in quickfix list",
		"Previous item in different file in quickfix list")

	M.nap("s", "normal! ]s", "normal! [s", "Next spell error", "Previous spell error")

	M.nap("t", "tnext", "tprevious", "Next tag", "Previous tag")
	M.nap("T", "tlast", "tfirst", "Last tag", "First tag")
	M.nap("<C-t>", "ptnext", "ptprevious", "Next tag in previous window", "Previous tag in previous window")

	M.nap("z", "normal! zj", "normal! zk", "Next fold", "Previous fold")
end

return M
