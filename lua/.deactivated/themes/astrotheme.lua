vim.pack.add { "https://github.com/AstroNvim/astrotheme" }
local c = require "astrotheme.palettes.astrodark"
require("astrotheme").setup {
    style = {
        transparent = false,
        inactive = false,
        float = true,
    },
    plugin_default = true,
    highlights = {
        global = {
            ["Folded"] = { fg = c.ui.text, bg = c.ui.base },
        },
    },
}
vim.cmd.colorscheme "astrodark"
