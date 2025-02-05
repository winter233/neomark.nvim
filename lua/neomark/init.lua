-- this file includes code from [todo-comments](https://github.com/folke/todo-comments.nvim),
-- licensed under the Apache License 2.0: http://www.apache.org/licecses/LICENSE-2.0
local config = require("neomark.config")
local Highlight = require("neomark.highlight")
local Cmgr = require("neomark.colormgr")
local jump = require("neomark.jump")
local Util = require("neomark.util")

local M = {}

M.setup = config.setup

function M.reset()
  require("plenary.reload").reload_module("neomark")
  require("neomark").setup()
end

function M.disable()
  require("neomark.highlight").stop()
end

function M.enable()
  require("neomark.highlight").start()
end

function M.next(opts)
  opts.up = false
  jump.jump(opts)
end

function M.prev(opts)
  opts.up = true
  jump.jump(opts)
end

function M.toggle()
  local word = vim.fn.expand("<cword>")
  if word == nil or word == '' then
    Util.warn("Empty string")
    return
  end
  if Cmgr.is_keyword() ~= 0 then
    Cmgr.remove()
    Highlight.remove_highlight()
  else
    Cmgr.add_keyword()
    Highlight.update()
  end
end

function M.clear()
  Cmgr.clear()
  Highlight.remove_highlight()
end

return M
