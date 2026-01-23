MiniDeps.now(function()
    MiniDeps.add { source = "folke/tokyonight.nvim", name = "catppuccin" }
    require("tokyonight").setup {
        on_colors = function(colors)
            colors.fg = "#bbc2cf"
            colors.fg_dark = "#5b6268"
            colors.fg_float = "#bbc2cf"
            colors.fg_gutter = "#5b6268"
            colors.fg_sidebar = "#bbc2cf"
            colors.bg = "#282c34"
            colors.bg_dark = "#21242b"
            colors.bg_dark1 = "#1b2229"
            colors.bg_float = "#21242b"
            colors.bg_highlight = "#3f444a"
            colors.bg_popup = "#21242b"
            colors.bg_search = "#2257a0"
            colors.bg_sidebar = "#21242b"
            colors.bg_statusline = "#21242b"
            colors.bg_visual = "#3f444a"
            colors.border = "#202328"
            colors.border_highlight = "#51afef"
            colors.black = "#1c1e1e"
            colors.comment = "#5b6268"
            colors.dark3 = "#5b6268"
            colors.dark5 = "#73797e"
            colors.red = "#ff6c6b"
            colors.red1 = "#c8504e"
            colors.green = "#98be65"
            colors.green1 = "#4db5bd" -- Mapped to doom-teal
            colors.green2 = "#5699af" -- Mapped to doom-dark_cyan
            colors.yellow = "#ecbe7b"
            colors.blue = "#51afef"
            colors.magenta = "#c678dd"
            colors.magenta2 = "#f06090"
            colors.purple = "#a9a1e1" -- mapped to doom-violet
            colors.cyan = "#46d9ff"
            colors.teal = "#4db5bd"
            colors.orange = "#da8548"
            colors.blue0 = "#4588c4"
            colors.blue1 = "#78c0f5"
            colors.blue2 = "#4db5bd"
            colors.blue5 = "#90e8ff"
            colors.blue6 = "#c0f5ff"
            colors.blue7 = "#2257a0"
            colors.error = "#c8504e"
            colors.warning = "#ecbe7b"
            colors.info = "#51afef"
            colors.hint = "#98be65"
            colors.todo = "#da8548"
            colors.diff = {
                add = "#2A3B31",
                change = "#262F40",
                delete = "#3D2A2E",
                text = "#5b6268",
            }
            colors.git = {
                add = "#98be65",
                change = "#51afef",
                delete = "#ff6c6b",
                ignore = "#5b6268",
            }
            colors.terminal = {
                black = "#1c1e1e",
                black_bright = "#5b6268",
                red = "#ff6c6b",
                red_bright = "#ff6c6b",
                green = "#98be65",
                green_bright = "#98be65",
                yellow = "#ecbe7b",
                yellow_bright = "#ecbe7b",
                blue = "#51afef",
                blue_bright = "#51afef",
                magenta = "#c678dd",
                magenta_bright = "#c678dd",
                cyan = "#46d9ff",
                cyan_bright = "#46d9ff",
                white = "#bbc2cf",
                white_bright = "#dfdfdf",
            }
            colors.terminal_black = "#5b6268"
            colors.none = "NONE"
            colors.rainbow = {
                "#ff6c6b", -- red
                "#da8548", -- orange
                "#ecbe7b", -- yellow
                "#98be65", -- green
                "#51afef", -- blue
                "#c678dd", -- magenta
                "#a9a1e1", -- violet
                "#46d9ff", -- cyan
            }
        end,
        cache = false,
        styles = {
            floats = "transparent",
        },
        plugins = {
            all = true,
        },
    }

    vim.cmd [[colorscheme tokyonight]]
end)
