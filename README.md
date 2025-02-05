# Neomark

**Neomark** is a lua plugin for Neovim >= 0.8.0 to highlight several cursor word with different colors and navigate between them.

## Features

- highlight as many keywords as you want, defualt 8.
- jump to prev/next marked keyword.

## Requirements

- Neovim >= 0.8.0

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "winter233/neomark.nvim",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings:
    -- colors = { "#06989a", "#A4E57E", "#FFDB72", "#FF7272", "#FFB3FF", "#9999FF", "#729FCF", "#10B981" },
  }
  keys = {
    -- your key maps
    -- { "<F7>",  "<leader>mn" , remap = true },
    -- { "<F19>", "<leader>mp", remap = true},
    -- { "<F8>",  "<leader>m]" , remap = true},
    -- { "<F20>", "<leader>m[", remap = true},
    -- { "<leader>mm", function() require("neomark").toggle() end, desc = "Mark/Unmark word under cursor"},
    -- { "<leader>mc", function() require("neomark").clear() end, desc = "Unmark all words"},
    -- { "<leader>mp", function() require("neomark").prev({ recursive = true }) end, desc = "jump to prev marked word"},
    -- { "<leader>mn", function() require("neomark").next({ recursive = true }) end, desc = "jump to next marked word"},
    -- { "<leader>m[", function() require("neomark").prev({ recursive = true, any = true }) end, desc = "jump to prev any marked word"},
    -- { "<leader>m]", function() require("neomark").next({ recursive = true, any = true }) end, desc = "jump to next any marked word"},
  }
}
```

## Credits
- this project includes code from [todo-comments](https://github.com/folke/todo-comments.nvim)
- [inkarkat/vim-mark](https://github.com/inkarkat/vim-mark) for inspiration

<!-- markdownlint-disable-file MD033 -->
<!-- markdownlint-configure-file { "MD013": { "line_length": 120 } } -->
<!-- markdownlint-configure-file { "MD004": { "style": "sublist" } } -->
