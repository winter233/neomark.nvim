-- this file includes code from [todo-comments](https://github.com/folke/todo-comments.nvim),
-- licensed under the Apache License 2.0: http://www.apache.org/licecses/LICENSE-2.0
local Config = require("neomark.config")
local Cmgr = require("neomark.colormgr")

local M = {}
M.enabled = false
M.bufs = {}
M.wins = {}
M.ac = {}

---@alias NeomarkDirty table<number, boolean>
---@type table<buffer, {dirty:NeomarkDirty}>
M.state = {}

function M.match(str, pattern)
  local pos = {}
  local start = 0
  local m
  while true do
    m = vim.fn.matchstrpos(str, [[\v\C]] .. pattern, start)
    if m[2] == -1 then
      break
    end
    table.insert(pos, m)
    start = m[3]
  end
  return pos
end

-- This method returns nil if this buf doesn't have a treesitter parser
--- @return boolean? true or false otherwise
function M.is_comment(buf, row, col)
  return true
end

local function add_highlight(buffer, ns, hl, line, from, to)
  -- vim.api.nvim_buf_set_extmark(buffer, ns, line, from, {
  --   end_line = line,
  --   end_col = to,
  --   hl_group = hl,
  --   priority = 500,
  -- })
  vim.api.nvim_buf_add_highlight(buffer, ns, hl, line, from, to)
end

function M.get_state(buf)
  if not M.state[buf] then
    M.state[buf] = { dirty = {}, comments = {} }
  end
  return M.state[buf]
end

function M.redraw(buf, first, last)
  first = math.max(first, 0)
  last = math.min(last, vim.api.nvim_buf_line_count(buf))
  local state = M.get_state(buf)
  state.dirty = {}
  for i = first, last do
    state.dirty[i] = true
  end
  if not M.timer then
    M.timer = vim.defer_fn(M.update, Config.options.highlight.throttle)
  end
end

---@type vim.loop.Timer
M.timer = nil

function M.update()
  M.timer = nil
  for buf, state in pairs(M.state) do
    if vim.api.nvim_buf_is_valid(buf) then
      if not vim.tbl_isempty(state.dirty) then
        local dirty = vim.tbl_keys(state.dirty)
        table.sort(dirty)

        local i = 1
        while i <= #dirty do
          local first = dirty[i]
          local last = dirty[i]
          while dirty[i + 1] == dirty[i] + 1 do
            i = i + 1
            last = dirty[i]
          end
          M.highlight(buf, first, last)
          i = i + 1
        end
      end
    else
      M.state[buf] = nil
    end
  end
end

-- highlights the range for the given buf
function M.highlight(buf, first, last, _event)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, Config.ns, first, last + 1)

  local pattern = Cmgr.get_all_keywords()
  if not pattern or pattern == "" or pattern == "()" then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, first, last + 1, false)
  for l, line in ipairs(lines) do
    local pos = M.match(line, pattern)
    for _, val in ipairs(pos) do
      if val[1] ~= "" then
        local lnum = first + l - 1
        local hl_idx = Cmgr.is_keyword('<' .. val[1] .. '>')
        local hl_bg = "NeomarkBg" .. hl_idx

        -- TODO: multiline
        add_highlight(buf, Config.ns, hl_bg, lnum, val[2], val[3])
      end

    end
  end
end

-- highlights the visible range of the window
function M.highlight_win(win, force)
  win = win or vim.api.nvim_get_current_win()
  if force ~= true and not M.is_valid_win(win) then
    return
  end

  vim.api.nvim_win_call(win, function()
    local buf = vim.api.nvim_win_get_buf(win)
    local first = vim.fn.line("w0") - 1
    local last = vim.fn.line("w$")
    M.redraw(buf, first, last)
  end)
end

function M.is_float(win)
  local opts = vim.api.nvim_win_get_config(win)
  return opts and opts.relative and opts.relative ~= ""
end

function M.is_valid_win(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  -- avoid E5108 after pressing q:
  if vim.fn.getcmdwintype() ~= "" then
    return false
  end
  -- dont do anything for floating windows
  if M.is_float(win) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  return M.is_valid_buf(buf)
end

function M.is_quickfix(buf)
  return vim.api.nvim_buf_get_option(buf, "buftype") == "quickfix"
end

function M.is_valid_buf(buf)
  -- Skip special buffers
  local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
  if buftype ~= "" and buftype ~= "quickfix" then
    return false
  end
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  if vim.tbl_contains(Config.options.highlight.exclude, filetype) then
    return false
  end
  return true
end

-- will attach to the buf in the window and highlight the active buf if needed
function M.attach(win)
  win = win or vim.api.nvim_get_current_win()
  if not M.is_valid_win(win) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)

  if not M.bufs[buf] then
    vim.api.nvim_buf_attach(buf, false, {
      on_lines = function(_event, _buf, _tick, first, _last, last_new)
        if not M.enabled then
          return true
        end
        -- detach from this buffer in case we no longer want it
        if not M.is_valid_buf(buf) then
          return true
        end

        M.redraw(buf, first, last_new)
      end,
      on_detach = function()
        M.state[buf] = nil
        M.bufs[buf] = nil
      end,
    })

    local highlighter = require("vim.treesitter.highlighter")
    local hl = highlighter.active[buf]
    if hl then
      -- TODO: remove
      -- also listen to TS changes so we can properly update the buffer based on is_comment
      hl.tree:register_cbs({
        on_bytes = function(_, _, row)
          M.redraw(buf, row, row + 1)
        end,
        on_changedtree = function(changes)
          for _, ch in ipairs(changes or {}) do
            M.redraw(buf, ch[1], ch[3] + 1)
          end
        end,
      })
    end

    M.bufs[buf] = true
    M.highlight_win(win)
    M.wins[win] = true
  elseif not M.wins[win] then
    M.highlight_win(win)
    M.wins[win] = true
  end
end

function M.stop()
  M.enabled = false
  pcall(vim.cmd, "autocmd! Neomark")
  pcall(vim.cmd, "augroup! Neomark")
  M.wins = {}

  ---@diagnostic disable-next-line: missing-parameter
  vim.fn.sign_unplace("neomark-signs")
  for buf, _ in pairs(M.bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_clear_namespace, buf, Config.ns, 0, -1)
    end
  end
  M.bufs = {}
end

function M.start()
  if M.enabled then
    M.stop()
  end
  M.enabled = true
  -- setup autocmds
  -- TODO: make some of the below configurable
  vim.api.nvim_exec(
    [[augroup Neomark 
        autocmd!
        autocmd BufWinEnter,WinNew * lua require("neomark.highlight").attach()
        autocmd WinScrolled * lua require("neomark.highlight").highlight_win()
        autocmd ColorScheme * lua vim.defer_fn(require("neomark.config").colors, 10)
      augroup end]],
    false
  )

  -- attach to all bufs in visible windows
  for _, win in pairs(vim.api.nvim_list_wins()) do
    M.attach(win)
  end
end

function M.remove_highlight()
  for buf, _ in pairs(M.state) do
    if vim.api.nvim_buf_is_valid(buf) then
       M.update()
    else
      M.state[buf] = nil
    end
    return
  end
end

return M
