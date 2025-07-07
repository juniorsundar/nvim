return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        enabled = false,
        config = function()
            local cyberdream = {
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
            }
            local kanagawa = {
                rosewater = "#c4746e",
                flamingo = "#a292a3",
                pink = "#d27e99",
                mauve = "#8992a7",
                red = "#E82424",
                maroon = "#c4746e",
                peach = "#b6927b",
                yellow = "#c4b28a",
                green = "#8a9a7b",
                teal = "#87a987",
                sky = "#8ea4a2",
                sapphire = "#949fb5",
                blue = "#8ba4b0",
                lavender = "#957FB8",
                text = "#c5c9c5",
                subtext1 = "#C8C093",
                subtext0 = "#a6a69c",
                overlay2 = "#9e9b93",
                overlay1 = "#7a8382",
                overlay0 = "#737c73",
                surface2 = "#625e5a",
                surface1 = "#393836",
                surface0 = "#282727",
                base = "#181616",
                mantle = "#1D1C19",
                crust = "#0d0c0c",
            }
            local config = {
                color_overrides = {
                    macchiato = cyberdream,
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
                    blink_cmp = true,
                    cmp = true,
                    dap = true,
                    dap_ui = true,
                    diffview = true,
                    flash = true,
                    gitsigns = true,
                    lsp_saga = true,
                    markdown = true,
                    mason = true,
                    mini = { enabled = true },
                    native_lsp = { enabled = true },
                    neogit = true,
                    notify = true,
                    nvim_surround = true,
                    snacks = true,
                    treesitter = false,
                    treesitter_context = true,
                    which_key = true,
                },
            }

            require("catppuccin").setup(config)
            vim.cmd.colorscheme "catppuccin-macchiato"
        end,
    },
    {
        "nvim-tree/nvim-web-devicons",
    },
    {
        'Mofiqul/vscode.nvim',
        enabled = false,
        config = function()
            vim.cmd.colorscheme "vscode"
        end
    },
    {
        "folke/tokyonight.nvim",
        enabled = false,
        lazy = false,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "storm",
                transparent = true,
                lualine_bold = true,
                styles = {
                    sidebars = "transparent",
                    floats = "transparent"
                }
            })
            vim.cmd [[colorscheme tokyonight]]
        end
    },
    {
        "AstroNvim/astrotheme",
        priority = 1000,
        enabled = true,
        lazy = false,
        config = function()
            local c = require("astrotheme.palettes.astrodark")
            require("astrotheme").setup({
                style = {
                    transparent = false,
                    float = false,
                },
                plugin_default = true,
                highlights = {
                    global = {
                        ["BlinkCmpMenu"] = { fg = c.ui.text, bg = c.ui.base },
                        ["BlinkCmpMenuBorder"] = { fg = c.ui.text, bg = c.ui.base },
                    }
                }
            })
            vim.cmd [[set fillchars+=eob:\ ]]
            vim.cmd [[colorscheme astrodark]]
        end
    }
}
