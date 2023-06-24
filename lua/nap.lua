local M = {}

-- Command execution.

---@class Command
---@field lhs string The lhs of map command
---@field rhs string|function The rhs of map command
---@field opts table|nil The opts  of map command

---@class OperatorConfig
---@field next Command Command to jump next.
---@field prev Command Command to jump next.
---@field mode string|table|nil Mode for the keybindings. If not set, "n" will be used.

-- Record the last operation.
---@type Command
local _next = nil
---@type Command
local _prev = nil

---@param command Command
local function replay(command)
  if command == nil then
    vim.notify(string.format('[nap] Nothing to repeat.'), vim.log.levels.INFO, { title = "nap.nvim" })
    return
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(command.lhs, true, false, true), "t", true)
end

---@param mode string|table
---@param next Command
---@param prev Command
local function map_nap(mode, next, prev)
  ---@param command Command
  local function map(command)
    local opts = command.opts or {}
    opts.desc = M.options.desc_prefix .. (opts.desc or "")
    -- String are always treated as expr. Functions are not expr unless user wants to.
    -- See :h :map-expression
    opts.expr = type(command.rhs) == "string" or (opts.expr or false)

    vim.keymap.set(mode, command.lhs, function()
      _next = next
      _prev = prev
      if type(command.rhs) == "string" then
        return command.rhs
      else
        return command.rhs()
      end
    end, opts)
  end

  map(next)
  map(prev)
end

-- Add or override an operator.
---@param operator string Operator key, usually is a single character.
---@param config false|OperatorConfig Operator configs, including commands and description.
function M.map(operator, config)
  local mode = config and config.mode or "n" or "n"
  local next_lhs = M.options.next_prefix .. operator
  local prev_lhs = M.options.prev_prefix .. operator

  if not config then
    vim.keymap.del(mode, next_lhs)
    vim.keymap.del(mode, prev_lhs)
    return
  end
  config.next.lhs = next_lhs
  config.prev.lhs = prev_lhs
  map_nap(mode, config.next, config.prev)
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

---@class Option
M.defaults = {
  next_prefix = "]",      -- <next_prefix><operator> to jump to next
  prev_prefix = "[",      -- <prev_prefix><operator> to jump to prev
  next_repeat = "<c-n>",  -- <next_repeat> to repeat jump to next
  prev_repeat = "<c-p>",  -- <prev_repeat> to repeat jump to prev
  desc_prefix = "[nap] ", -- Prefix string added to keymaps description
  -- All operators.
  ---@type table<string, OperatorConfig>
  operators = {
    ["a"] = {
      next = { rhs = "<cmd>tabnext<cr>", opts = { desc = "Next tab" } },
      prev = { rhs = "<cmd>tabprevious<cr>", opts = { desc = "Prev tab" } },
    },
    ["A"] = {
      next = { rhs = "<cmd>tablast<cr>", opts = { desc = "Last tab" } },
      prev = { rhs = "<cmd>tabfirst<cr>", opts = { desc = "First tab" } },
    },
    ["b"] = {
      next = { rhs = "<cmd>bnext<cr>", opts = { desc = "Next buffer" } },
      prev = { rhs = "<cmd>bprevious<cr>", opts = { desc = "Prev buffer" } },
    },
    ["B"] = {
      next = { rhs = "<cmd>blast<cr>", opts = { desc = "Last buffer" } },
      prev = { rhs = "<cmd>bfirst<cr>", opts = { desc = "First buffer" } },
    },
    ["d"] = {
      next = { rhs = vim.diagnostic.goto_next, opts = { desc = "Next diagnostic" } },
      prev = { rhs = vim.diagnostic.goto_prev, opts = { desc = "Prev diagnostic" } },
      mode = { "n", "v", "o" }
    },
    ["e"] = {
      next = { rhs = "g;", opts = { desc = "Older edit (change-list) item" } },
      prev = { rhs = "g,", opts = { desc = "Newer edit (change-list) item" } }
    },
    ["f"] = {
      next = { rhs = M.next_file, opts = { desc = "Next file" } },
      prev = { rhs = M.prev_file, opts = { desc = "Prev file" } },
    },
    ["F"] = {
      next = { rhs = M.last_file, opts = { desc = "Last file" } },
      prev = { rhs = M.first_file, opts = { desc = "First file" } },
    },
    ["l"] = {
      next = { rhs = "<cmd>lnext<cr>", opts = { desc = "Next loclist item" } },
      prev = { rhs = "<cmd>lprevious<cr>", opts = { desc = "Prev loclist item" } }
    },
    ["L"] = {
      next = { rhs = "<cmd>llast<cr>", opts = { desc = "Last loclist item" } },
      prev = { rhs = "<cmd>lfirst<cr>", opts = { desc = "First loclist item" } }
    },
    ["<C-l>"] = {
      next = { rhs = "<cmd>lnfile<cr>", opts = { desc = "Next loclist item in different file" } },
      prev = { rhs = "<cmd>lpfile<cr>", opts = { desc = "Prev loclist item in different file" } }
    },
    ["<M-l>"] = {
      next = { rhs = "<cmd>lnewer<cr>", opts = { desc = "Next loclist list" } },
      prev = { rhs = "<cmd>lolder<cr>", opts = { desc = "Prev loclist list" } }
    },
    ["q"] = {
      next = { rhs = "<cmd>cnext<cr>", opts = { desc = "Next quickfix item" } },
      prev = { rhs = "<cmd>cprevious<cr>", opts = { desc = "Prev quickfix item" } }
    },
    ["Q"] = {
      next = { rhs = "<cmd>clast<cr>", opts = { desc = "Last quickfix item" } },
      prev = { rhs = "<cmd>cfirst<cr>", opts = { desc = "First quickfix item" } }
    },
    ["<C-q>"] = {
      next = { rhs = "<cmd>cnfile<cr>", opts = { desc = "Next quickfix item in different file" } },
      prev = { rhs = "<cmd>cpfile<cr>", opts = { desc = "Prev quickfix item in different file" } }
    },
    ["<M-q>"] = {
      next = { rhs = "<cmd>cnewer<cr>", opts = { desc = "Next quickfix list" } },
      prev = { rhs = "<cmd>colder<cr>", opts = { desc = "Prev quickfix list" } }
    },
    ["s"] = {
      next = { rhs = "]s", opts = { desc = "Next spell error" } },
      prev = { rhs = "[s", opts = { desc = "Prev spell error" } },
      mode = { "n", "v", "o" },
    },
    ["t"] = {
      next = { rhs = "<cmd>tnext<cr>", opts = { desc = "Next tag" } },
      prev = { rhs = "<cmd>tprevious<cr>", opts = { desc = "Prev tag" } }
    },
    ["T"] = {
      next = { rhs = "<cmd>tlast<cr>", opts = { desc = "Last tag" } },
      prev = { rhs = "<cmd>tfirst<cr>", opts = { desc = "First tag" } }
    },
    ["<C-t>"] = {
      next = { rhs = "<cmd>ptnext<cr>", opts = { desc = "Next tag in previous window" } },
      prev = { rhs = "<cmd>ptprevious<cr>", opts = { desc = "Prev tag in previous window" } }
    },
    ["z"] = {
      next = { rhs = "zj", opts = { desc = "Next fold" } },
      prev = { rhs = "zk", opts = { desc = "Prev fold" } },
      mode = { "n", "v", "o" },
    },
    ["'"] = {
      next = { rhs = "]`", opts = { desc = "Next lowercase mark" } },
      prev = { rhs = "[`", opts = { desc = "Prev lowercase mark" } }
    },
  }
}

---@param options Option
function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})

  vim.keymap.set({ "n", "v", "o" }, M.options.next_repeat, function() replay(_next) end, { desc = "Repeat next" })
  vim.keymap.set({ "n", "v", "o" }, M.options.prev_repeat, function() replay(_prev) end, { desc = "Repeat prev" })

  for key, config in pairs(M.options.operators) do M.map(key, config) end
end

-- Plugin integration helpers. Users could assign these to some operator manually.

function M.gitsigns()
  -- Whether we are in a diff mode where "]c" "[c" will likely work better for hunks.
  local function in_diff_mode()
    return vim.wo.diff or vim.bo.filetype == "fugitive" or vim.bo.filetype == "git"
  end
  return {
    next = {
      rhs = function()
        if in_diff_mode() then return ']c' end
        vim.schedule(function() require("gitsigns").next_hunk({ preview = true }) end)
        return '<Ignore>'
      end,
      opts = { desc = "Next diff", expr = true }
    },
    prev = {
      rhs = function()
        if in_diff_mode() then return '[c' end
        vim.schedule(function() require("gitsigns").prev_hunk({ preview = true }) end)
        return '<Ignore>'
      end,
      opts = { desc = "Prev diff", expr = true },
    },
    mode = { "n", "v", "o" },
  }
end

function M.aerial()
  return {
    next = { rhs = "<cmd>AerialNext<cr>", opts = { desc = "Next outline symbol" } },
    prev = { rhs = "<cmd>AerialPrev<cr>", opts = { desc = "Prev outline symbol" } },
    mode = { "n", "v", "o" },
  }
end

function M.illuminate()
  return {
    next = { rhs = require('illuminate').goto_next_reference, opts = { desc = "Next cursor word" } },
    prev = { rhs = require('illuminate').goto_prev_reference, opts = { desc = "Prev cursor word" } },
    mode = { "n", "x", "o" }
  }
end

-- Deprecated APIs

-- Use M.map instead. Will be deleted in future.
--- @deprecated
function M.operator(key, config)
  if config and config.next.rhs == nil then
    local adapter = function(nap)
      if type(nap.command) == "string" then
        vim.cmd(nap.command)
      else
        nap.command()
      end
    end
    config.next = { rhs = adapter(config.next), opts = { desc = config.next.desc } }
    config.prev = { rhs = adapter(config.prev), opts = { desc = config.prev.desc } }
  end
  M.map(key, config)
end

-- Use M.map instead. Will be deleted in future.
--- @deprecated
function M.nap(key, next, prev, next_desc, prev_desc, modes)
  M.map(key, {
    next = { rhs = next, opts = { desc = next_desc }, },
    prev = { rhs = prev, opts = { desc = prev_desc }, },
    mode = modes,
  })
end

return M
