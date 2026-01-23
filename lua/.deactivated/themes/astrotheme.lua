MiniDeps.add { source = "AstroNvim/astrotheme" }
local c = require "astrotheme.palettes.astrodark"
require("astrotheme").setup {
    style = {
        transparent = false,
        float = false,
    },
    plugin_default = true,
    highlights = {
        global = {
            ["BlinkCmpMenu"] = { fg = c.ui.text, bg = c.ui.base },
            ["BlinkCmpMenuBorder"] = { fg = c.ui.text, bg = c.ui.base },
            ["Folded"] = { fg = c.ui.text, bg = c.ui.base },
        },
    },
}
vim.cmd.colorscheme "astrodark"
