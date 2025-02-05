-- this file includes code from [todo-comments](https://github.com/folke/todo-comments.nvim),
-- licensed under the Apache License 2.0: http://www.apache.org/licecses/LICENSE-2.0
local Util = require("neomark.util")
local Cmgr = require("neomark.colormgr")

--- @class NeomarkConfig
local M = {}

M.keywords = {}
--- @type NeomarkOptions
M.options = {}
M.loaded = false

M.ns = vim.api.nvim_create_namespace("neomark")

--- @class NeomarkOptions
-- TODO: add support for markdown todos
local defaults = {
  colors = { "#06989a", "#A4E57E", "#FFDB72", "#FF7272", "#FFB3FF", "#9999FF", "#729FCF", "#10B981" },
  gui_style = {
    fg = "NONE", -- The gui style to use for the fg highlight group.
    bg = "BOLD", -- The gui style to use for the bg highlight group.
  },
  highlight = {
    exclude = {}, -- list of file types to exclude highlighting
    throttle = 200,
  },
}


function M.setup(options)
  if vim.fn.has("nvim-0.8.0") == 0 then
    error("neomark needs Neovim >= 0.8.0. Use the 'neovim-pre-0.8.0' branch for older versions")
  end
  M._options = options
  if vim.api.nvim_get_vvar("vim_did_enter") == 0 then
    vim.defer_fn(function()
      M._setup()
    end, 0)
  else
    M._setup()
  end
end

function M._setup()
  M.options = vim.tbl_deep_extend("force", {}, defaults, M._options or {})
  M._options = nil
  M.colors()
  Cmgr.create(#M.options.colors)
  require("neomark.highlight").start()
  M.loaded = true
end

-- TODO:no need to set aotocmd, set autocmd in search
function M.colors()
  local normal = Util.get_hl("Normal")
  local normal_fg = normal.foreground
  local normal_bg = normal.background
  local default_dark = "#000000"
  local default_light = "#FFFFFF"
  if not normal_fg and not normal_bg then
    normal_fg = default_light
    normal_bg = default_dark
  elseif not normal_fg then
    normal_fg = Util.maximize_contrast(normal_bg, default_dark, default_light)
  elseif not normal_bg then
    normal_bg = Util.maximize_contrast(normal_fg, default_dark, default_light)
  end
  local fg_gui = M.options.gui_style.fg
  local bg_gui = M.options.gui_style.bg

  local sign_hl = Util.get_hl("SignColumn")
  local sign_bg = (sign_hl and sign_hl.background) and sign_hl.background or "NONE"

  for idx, kw_color in pairs(M.options.colors) do
    kw_color = kw_color or "default"

    assert(kw_color:sub(1, 1) == "#")
    local hex = kw_color
    local fg = Util.maximize_contrast(hex, normal_fg, normal_bg)

    vim.cmd("hi def NeomarkBg" .. idx .. " guibg=" .. hex .. " guifg=" .. fg .. " gui=" .. bg_gui)
    vim.cmd("hi def NeomarkFg" .. idx .. " guibg=NONE guifg=" .. hex .. " gui=" .. fg_gui)
  end
end

return M
