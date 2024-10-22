return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        config = function()
            local modus_vivendi = {
                color_overrides = {
                    macchiato = {
                        rosewater = "#fae3e0",     -- Light red/rosewater equivalent
                        flamingo = "#f8c7c3",      -- Flamingo equivalent
                        pink = "#d7a3ff",          -- Bright pink
                        mauve = "#a899ff",         -- Mauve equivalent
                        red = "#ff8059",           -- Bright red
                        maroon = "#ff6a6a",        -- Maroon equivalent
                        peach = "#ffa94d",         -- Bright peach/orange
                        yellow = "#e5c07b",        -- Yellow equivalent
                        green = "#44bc44",         -- Bright green
                        teal = "#00bc7f",          -- Teal equivalent
                        sky = "#00f5e9",           -- Sky/cyan equivalent
                        sapphire = "#1fa3cf",      -- Sapphire equivalent
                        blue = "#4f97d7",          -- Bright blue
                        lavender = "#d7afff",      -- Light purple
                        text = "#ffffff",          -- Foreground (bright text)
                        subtext1 = "#dcdcdc",      -- Subtext1 equivalent
                        subtext0 = "#bcbcbc",      -- Subtext0 equivalent
                        overlay2 = "#9c9c9c",      -- Overlay2 equivalent
                        overlay1 = "#8c8c8c",      -- Overlay1 equivalent
                        overlay0 = "#7c7c7c",      -- Overlay0 equivalent
                        surface2 = "#5b6078",      -- Surface2 equivalent
                        surface1 = "#494d64",      -- Surface1 equivalent
                        surface0 = "#363a4f",      -- Surface0 equivalent
                        base = "#000000",          -- Background
                        mantle = "#121212",        -- Darker background
                        crust = "#1e1e1e",         -- Dark crust (similar to bg_highlight)
                    },
                },
                custom_highlights = function(colors)
                    return {
                    }
                end,
                highlight_overrides = {
                    macchiato = function(colors)
                        return {
                            NormalFloat = { fg = colors.text, bg = colors.mantle },
                            Comment = { fg = colors.overlay1 },
                            LineNr = { fg = colors.overlay1 },
                            CursorLineNr = { fg = colors.text },
                            WhichKey = { fg = colors.text, bg = colors.base },
                            WhichKeyNormal = { fg = colors.text, bg = colors.base },
                            Folded = { fg = colors.crust, bg = colors.none },
                            ["@neorg.tags.ranged_verbatim.code_block"] = { bg = colors.crust }
                        }
                    end,
                },
                transparent_background = false,
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    treesitter = false,
                    -- markdown = true,
                    neogit = true,
                    treesitter_context = true,
                    lsp_saga = true,
                    diffview = true,
                    which_key = true,
                    mason = true,
                    notify = true,
                    native_lsp = {
                        enabled = true,
                    },
                    mini = true,
                    nvim_surround = true
                },
            }
            local cyberdream = {
                color_overrides = {
                    macchiato = {
                        base = "#16181A",
                        blue = "#5EA1FF",
                        crust = "#3C4048",
                        flamingo = "#FF9F9F",
                        green = "#5EFF6C",
                        lavender = "#FF5EF1",
                        mantle = "#1E2124",
                        maroon = "#D96666",
                        mauve = "#BD5EFF",
                        overlay0 = "#474A55",
                        overlay1 = "#5A5E6B",
                        overlay2 = "#6E7280",
                        peach = "#FFBD5E",
                        pink = "#FF5EA0",
                        red = "#FF6E5E",
                        rosewater = "#FFD1DC",
                        sapphire = "#4A90E2",
                        sky = "#5EF1FF",
                        subtext0 = "#8A8E99",
                        subtext1 = "#A0A4B8",
                        surface0 = "#26282E",
                        surface1 = "#2E3138",
                        surface2 = "#363940",
                        teal = "#64D8CB",
                        text = "#FFFFFF",
                        yellow = "#F1FF5E",
                    },
                },
                custom_highlights = function(colors)
                    return {
                    }
                end,
                highlight_overrides = {
                    macchiato = function(colors)
                        return {
                            NormalFloat = { fg = colors.text, bg = colors.mantle },
                            Comment = { fg = colors.overlay1 },
                            LineNr = { fg = colors.overlay1 },
                            CursorLineNr = { fg = colors.text },
                            WhichKey = { fg = colors.text, bg = colors.base },
                            WhichKeyNormal = { fg = colors.text, bg = colors.base },
                            Folded = { fg = colors.crust, bg = colors.none },
                        }
                    end,
                },
                transparent_background = false,
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    treesitter = false,
                    -- markdown = true,
                    neogit = true,
                    treesitter_context = true,
                    lsp_saga = true,
                    diffview = true,
                    which_key = true,
                    mason = true,
                    notify = true,
                    native_lsp = {
                        enabled = true,
                    },
                    mini = true,
                    nvim_surround = true
                },
            }

            -- require("catppuccin").setup(cyberdream)
            require("catppuccin").setup(modus_vivendi)
            vim.cmd.colorscheme("catppuccin-macchiato")
        end,
    },
    {
        "nvim-tree/nvim-web-devicons",
    },
}
