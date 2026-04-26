require("micro.pack").add { src = "gh:catppuccin/nvim", name = "catppuccin" }

local config = {
    color_overrides = {},
    custom_highlights = function(colors)
        return {}
    end,
    highlight_overrides = {
        mocha = function(colors)
            return {
                NormalFloat = { fg = colors.text, bg = colors.base },
                LineNr = { fg = colors.overlay1 },
                CursorLineNr = { fg = colors.text },
                Comment = { fg = colors.surface2 },
                WhichKey = { fg = colors.blue, bg = nil },
                WhichKeyNormal = { fg = colors.text, bg = nil },
                WhichKeyDesc = { fg = colors.maroon },
                Folded = { fg = colors.overlay1, bg = colors.none },
                BlinkCmpMenu = { fg = colors.text, bg = colors.base },
                BlinkCmpMenuBorder = { fg = colors.text, bg = colors.base },
            }
        end,
    },
    transparent_background = false,
    float = {
        transparent = false,
    },
    integrations = {
        diffview = true,
        flash = true,
        gitsigns = true,
        mason = true,
        mini = {
            enabled = true,
        },
        neogit = true,
        nvim_surround = true,
        render_markdown = true,
        snacks = {
            enabled = true,
        },
        which_key = true,
    },
}
require("catppuccin").setup(config)
vim.cmd.colorscheme "catppuccin-mocha"
