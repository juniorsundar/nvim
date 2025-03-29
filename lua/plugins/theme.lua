return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        config = function()
            local cyberdream = {
                color_overrides = {
                    macchiato = {
                        base = "#16181a",
                        blue = "#5ea1ff",
                        crust = "#3c4048",
                        flamingo = "#ff9f9f",
                        green = "#5eff6c",
                        lavender = "#ff5ef1",
                        mantle = "#1e2124",
                        maroon = "#d96666",
                        mauve = "#bd5eff",
                        overlay0 = "#474a55",
                        overlay1 = "#5a5e6b",
                        overlay2 = "#6e7280",
                        peach = "#ffbd5e",
                        pink = "#ff5ea0",
                        red = "#ff6e5e",
                        rosewater = "#ffd1dc",
                        sapphire = "#4a90e2",
                        sky = "#5ef1ff",
                        subtext0 = "#8a8e99",
                        subtext1 = "#a0a4b8",
                        surface0 = "#26282e",
                        surface1 = "#2e3138",
                        surface2 = "#363940",
                        teal = "#64d8cb",
                        text = "#ffffff",
                        yellow = "#f1ff5e",
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
                    markdown = true,
                    neogit = true,
                    snacks = true,
                    blink_cmp = true,
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
