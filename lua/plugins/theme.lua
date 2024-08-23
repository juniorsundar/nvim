return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        config = function()
            require("catppuccin").setup({
                color_overrides = {
                    macchiato = {
                        rosewater = "#ffd1dc",
                        flamingo = "#ff9f9f",
                        pink = "#ff5ea0",
                        mauve = "#bd5eff",
                        red = "#ff6e5e",
                        maroon = "#d96666",
                        peach = "#ffbd5e",
                        yellow = "#f1ff5e",
                        green = "#5eff6c",
                        teal = "#64d8cb",
                        sky = "#5ef1ff",
                        sapphire = "#4a90e2",
                        blue = "#5ea1ff",
                        lavender = "#ff5ef1",
                        text = "#ffffff",
                        subtext1 = "#a0a4b8",
                        subtext0 = "#8a8e99",
                        overlay2 = "#6e7280",
                        overlay1 = "#5a5e6b",
                        overlay0 = "#474a55",
                        surface2 = "#363940",
                        surface1 = "#2e3138",
                        surface0 = "#26282e",
                        base = "#16181a",
                        mantle = "#1e2124",
                        crust = "#3c4048",
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
                    alpha = true,
                    barbar = true,
                    flash = true,
                    markdown = true,
                    neogit = true,
                    grug_far = true,
                    treesitter_context = true,
                    lsp_saga = true,
                    lsp_trouble = true,
                    diffview = true,
                    which_key = true,
                    mason = true,
                    noice = true,
                    notify = true,
                    native_lsp = {
                        enabled = true,
                    },
                    mini = true,
                    nvim_surround = true
                },
            })
            vim.cmd.colorscheme("catppuccin-macchiato")
        end,
    },
    {
        "nvim-tree/nvim-web-devicons",
    },
}
