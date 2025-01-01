return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        config = function()
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
                    return {}
                end,
                highlight_overrides = {
                    macchiato = function(colors)
                        return {
                            NormalFloat = { fg = colors.text, bg = colors.base },
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
                    snacks = true,
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
                    nvim_surround = true,
                },
            }

            require("catppuccin").setup(cyberdream)
            vim.cmd.colorscheme "catppuccin-macchiato"
        end,
    },
    {
        "nvim-tree/nvim-web-devicons",
    },
}
