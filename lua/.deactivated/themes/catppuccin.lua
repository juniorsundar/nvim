MiniDeps.now(function()
    MiniDeps.add { source = "catppuccin/nvim", name = "catppuccin" }

    local doom_light = {
        crust = "#f0f0f0",
        mantle = "#f0f0f0",
        base = "#fafafa",
        surface0 = "#9ca0a4",
        surface1 = "#424242",
        surface2 = "#2e2e2e",
        overlay0 = "#9ca0a4",
        overlay1 = "#424242",
        overlay2 = "#1e1e1e",
        subtext0 = "#73797e",
        subtext1 = "#1e1e1e",
        text = "#383a42",
        red = "#e45649",
        peach = "#da8548",
        yellow = "#986801",
        green = "#50a14f",
        teal = "#4db5bd",
        sky = "#0184bc",
        sapphire = "#005478",
        blue = "#4078f2",
        lavender = "#b751b6",
        mauve = "#a626a4",
        pink = "#ca626a4",
        maroon = nil,
        flamingo = nil,
        rosewater = nil,
    }
    local doom_dark = {
        crust = "#1b2229",
        mantle = "#21242b",
        base = "#282c34",
        surface0 = "#3f444a",
        surface1 = "#5b6268",
        surface2 = "#73797e",
        overlay0 = "#3f444a",
        overlay1 = "#5b6268",
        overlay2 = "#9ca0a4",
        subtext0 = "#73797e",
        subtext1 = "#9ca0a4",
        text = "#bbc2cf",
        red = "#ff6c6b",
        peach = "#da8548",
        yellow = "#ecbe7b",
        green = "#98be65",
        teal = "#4db5bd",
        sky = "#46d9ff",
        sapphire = "#5699af",
        blue = "#51afef",
        lavender = "#a9a1e1",
        mauve = "#c678dd",
        pink = "#c678dd",
        maroon = nil,
        flamingo = nil,
        rosewater = nil,
    }
    local config = {
        color_overrides = {
            macchiato = doom_dark,
            latte = doom_light,
        },
        custom_highlights = function(colors)
            return {}
        end,
        highlight_overrides = {
            macchiato = function(colors)
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
            transparent = true,
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
    -- vim.cmd.colorscheme "catppuccin-macchiato"
end)
