-- this file includes code from [todo-comments](https://github.com/folke/todo-comments.nvim),
-- licensed under the Apache License 2.0: http://www.apache.org/licecses/LICENSE-2.0
local highlight = require("neomark.highlight")
local util = require("neomark.util")
local Cmgr = require("neomark.colormgr")

local M = {}

function M.jump(opts)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  local pos = vim.api.nvim_win_get_cursor(win)

  local from = pos[1] + 1
  local to = vim.api.nvim_buf_line_count(buf)

  if opts.up then
    from = pos[1] - 1
    to = 1
  end

  ---@type string
  local pattern
  if opts.any then
    pattern = Cmgr.get_all_keywords()
  else
    pattern = Cmgr.get_current_keyword()
  end
  if not pattern or pattern == "" or pattern == "()" then
    util.warn("No neomarks")
    return
  end

  -- search current line
  local line = vim.api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false)[1] or ""
  local success, ms = pcall(highlight.match, line, pattern)
  -- check return code, check matches
  if success and ms then
    if opts.up then
      for i = #ms, 1, -1 do
        if ms[i][2] < pos[2] then
          vim.api.nvim_win_set_cursor(win, { pos[1], ms[i][2] })
          return
        end
      end
    else
      for _, val in ipairs(ms) do
        if val[2] > pos[2] then
          vim.api.nvim_win_set_cursor(win, { pos[1], val[2] })
          return
        end
      end
    end
  end

  local col = 0

  local search_line = function(s, e)
    local m
    for l = s, e, opts.up and -1 or 1 do
      line = vim.api.nvim_buf_get_lines(buf, l - 1, l, false)[1] or ""
      success, m = pcall(highlight.match, line, pattern)
      if success and #m > 0 then
        col = opts.up and m[#m][2] or m[1][2]
        vim.api.nvim_win_set_cursor(win, { l, col })
        return true
      end
    end
    return false
  end

  -- check lines
  if search_line(from, to) then
    return
  end

  if opts.recursive then
    if opts.up then
      from = vim.api.nvim_buf_line_count(buf)
      to = pos[1] + 1
    else
      from = 1
      to = pos[1] - 1
    end
    if search_line(from, to) then
      return
    end
    if opts.up then
      for i = #ms, 1, -1 do
        if ms[i][2] > pos[2] then
          vim.api.nvim_win_set_cursor(win, { pos[1], ms[i][2] })
          return
        end
      end
    else
      for _, val in ipairs(ms) do
        if val[2] < pos[2] then
          vim.api.nvim_win_set_cursor(win, { pos[1], val[2] })
          return
        end
      end
    end
  else
    util.warn("reaches the end")
  end

  util.warn("No more mark to jump to")
end

return M
