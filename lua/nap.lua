local M = {}


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
      string.format('[nap.nvim] [%s] Nothing to repeat.', norp and 'Next' or 'Prev'),
      vim.log.levels.INFO,
      { title = "nap.nvim", icon = norp and '-->' or '<--' }
    )
  end
end

---Soft deprecated, use operator function instead.
-- Add keymaps to navigate between Next And Prev.
---@param key string Operator key, usually is a single character.
---@param next string|function Command to jump next.
---@param prev string|function Command to jump next.
---@param next_desc string Description of jump next.
---@param prev_desc string Description of jump next.
---@param modes table|nil Mode for the keybindings.
function M.nap(key, next, prev, next_desc, prev_desc, modes)
  M.operator(key, {
    next = { command = next, desc = next_desc, },
    prev = { command = prev, desc = prev_desc, },
    mode = modes,
  })
end

---@class Command
---@field command string|function Command to jump next or prev.
---@field desc string Description of the command.

---@class OperatorConfig
---@field next Command Command to jump next.
---@field prev Command Command to jump next.
---@field mode string|table|nil Mode for the keybindings. If not set, "n" will be used.

-- Add or override an operator.
---@param key string Operator key, usually is a single character.
---@param config false|OperatorConfig Operator configs, including commands and description.
function M.operator(key, config)
  if not config then return end
  local next_key = M.options.next_prefix .. key
  local prev_key = M.options.prev_prefix .. key
  local mode = config.mode or "n"
  vim.keymap.set(mode, next_key, function() exec(config.next.command, config.prev.command, true) end,
    { desc = M.options.desc_prefix .. config.next.desc })
  vim.keymap.set(mode, prev_key, function() exec(config.next.command, config.prev.command, false) end,
    { desc = M.options.desc_prefix .. config.prev.desc })
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

-- Jump list

function M.next_jump_list()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-i>", true, false, true), "t", true)
end

function M.prev_jump_list()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, false, true), "t", true)
end

-- Setup.

---@class Option
M.defaults = {
  next_prefix = "<c-n>", -- <next_prefix><operator> to jump to next
  prev_prefix = "<c-p>", -- <prev_prefix><operator> to jump to prev
  next_repeat = "<c-n>", -- <next_repeat> to repeat jump to next
  prev_repeat = "<c-p>", -- <prev_repeat> to repeat jump to prev
  desc_prefix = "[nap] ", -- Prefix string added to keymaps description
  -- All operators.
  ---@type table<string, OperatorConfig>
  operators = {
    ["a"] = {
      next = { command = "tabnext", desc = "Next tab", },
      prev = { command = "tabprevious", desc = "Prev tab", },
    },
    ["A"] = {
      next = { command = "tablast", desc = "Last tab", },
      prev = { command = "tabfirst", desc = "First tab", },
    },
    ["b"] = {
      next = { command = "bnext", desc = "Next buffer", },
      prev = { command = "bprevious", desc = "Prev buffer", },
    },
    ["B"] = {
      next = { command = "blast", desc = "Last buffer", },
      prev = { command = "bfirst", desc = "First buffer", },
    },
    ["c"] = {
      next = { command = "normal! g,", desc = "Next change-list item", },
      prev = { command = "normal! g;", desc = "Prev change-list item", }
    },
    ["d"] = {
      next = { command = vim.diagnostic.goto_next, desc = "Next diagnostic", },
      prev = { command = vim.diagnostic.goto_prev, desc = "Prev diagnostic", },
      mode = { "n", "v", "o" }
    },
    ["f"] = {
      next = { command = M.next_file, desc = "Next file", },
      prev = { command = M.prev_file, desc = "Prev file", },
    },
    ["F"] = {
      next = { command = M.last_file, desc = "Last file", },
      prev = { command = M.first_file, desc = "First file", },
    },
    ["j"] = {
      next = { command = M.next_jump_list, desc = "Next jump-list item", },
      prev = { command = M.prev_jump_list, desc = "Prev jump-list item" },
    },
    ["l"] = {
      next = { command = "lnext", desc = "Next loclist item", },
      prev = { command = "lprevious", desc = "Prev loclist item" },
    },
    ["L"] = {
      next = { command = "llast", desc = "Last loclist item", },
      prev = { command = "lfirst", desc = "First loclist item" },
    },
    ["<C-l>"] = {
      next = { command = "lnfile", desc = "Next loclist item in different file", },
      prev = { command = "lpfile", desc = "Prev loclist item in different file" },
    },
    ["<M-l>"] = {
      next = { command = "lnewer", desc = "Next loclist list", },
      prev = { command = "lolder", desc = "Prev loclist list" },
    },
    ["m"] = {
      next = { command = "normal! ]`", desc = "Next lowercase mark", },
      prev = { command = "normal! [`", desc = "Prev lowercase mark" },
    },
    ["q"] = {
      next = { command = "cnext", desc = "Next quickfix item", },
      prev = { command = "cprevious", desc = "Prev quickfix item" },
    },
    ["Q"] = {
      next = { command = "clast", desc = "Last quickfix item", },
      prev = { command = "cfirst", desc = "First quickfix item" },
    },
    ["<C-q>"] = {
      next = { command = "cnfile", desc = "Next quickfix item in different file", },
      prev = { command = "cpfile", desc = "Prev quickfix item in different file" },
    },
    ["<M-q>"] = {
      next = { command = "cnewer", desc = "Next quickfix list", },
      prev = { command = "colder", desc = "Prev quickfix list" },
    },
    ["s"] = {
      next = { command = "normal! ]s", desc = "Next spell error", },
      prev = { command = "normal! [s", desc = "Prev spell error", },
      mode = { "n", "v", "o" },
    },
    ["t"] = {
      next = { command = "tnext", desc = "Next tag", },
      prev = { command = "tprevious", desc = "Prev tag" },
    },
    ["T"] = {
      next = { command = "tlast", desc = "Last tag", },
      prev = { command = "tfirst", desc = "First tag" },
    },
    ["<C-t>"] = {
      next = { command = "ptnext", desc = "Next tag in previous window", },
      prev = { command = "ptprevious", desc = "Prev tag in previous window" },
    },
    ["z"] = {
      next = { command = "normal! zj", desc = "Next fold", },
      prev = { command = "normal! zk", desc = "Prev fold", },
      mode = { "n", "v", "o" },
    },
  }
}

---@param options Option
function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})

  vim.keymap.set({ "n", "v", "o" }, M.options.next_repeat, function() exec_last(true) end, { desc = "Repeat next" })
  vim.keymap.set({ "n", "v", "o" }, M.options.prev_repeat, function() exec_last(false) end, { desc = "Repeat prev" })

  if M.options.next_repeat == '<cr>' or M.options.prev_repeat == '<cr>' then
    -- If <cr> is used to repeat jump, it should be disabled in quickfix or command window
    vim.api.nvim_create_autocmd(
      "FileType", {
      pattern = { "qf" },
      command = [[nnoremap <buffer> <CR> <CR>]]
    })
    vim.api.nvim_create_autocmd(
      "CmdwinEnter", {
      command = [[nnoremap <buffer> <CR> <CR>]]
    })
  end

  for key, config in pairs(M.options.operators) do M.operator(key, config) end
end

-- Plugin integration helpers. Users could assign these to some operator manually.

function M.gitsigns()
  -- Whether we are in a diff mode where "]c" "[c" will likely work better for hunks.
  local function in_diff_mode()
    return vim.wo.diff or vim.wo.scrollbind or vim.bo.filetype == "fugitive" or vim.bo.filetype == "git"
  end
  return {
    next = {
      command = function()
        if in_diff_mode() then
          vim.cmd("normal ]c")
        else
          require("gitsigns").next_hunk({ preview = true })
        end
      end,
      desc = "Next diff",
    },
    prev = {
      command = function()
        if in_diff_mode() then
          vim.cmd("normal [c")
        else
          require("gitsigns").prev_hunk({ preview = true })
        end
      end,
      desc = "Prev diff",
    },
    mode = { "n", "v", "o" },
  }
end

function M.aerial()
  return {
    next = { command = "AerialNext", desc = "Next outline symbol", },
    prev = { command = "AerialPrev", desc = "Previous outline symbol", },
    mode = { "n", "v", "o" },
  }
end

function M.illuminate()
  return {
    next = { command = require('illuminate').goto_next_reference, desc = "Next cursor word", },
    prev = { command = require('illuminate').goto_prev_reference, desc = "Prev cursor word", },
    mode = { "n", "x", "o" }
  }
end

return M
