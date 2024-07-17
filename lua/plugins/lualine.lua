return {
    "nvim-lualine/lualine.nvim",
    config = function()
        local lualine = require "lualine"
        local cyberdream = {
            bg       = '#1e2124',
            blue     = '#5ea1ff',
            cyan     = '#64d8cb',
            darkblue = '#081633',
            fg       = '#ffffff',
            green    = '#5eff6c',
            magenta  = '#ff5ef1',
            orange   = '#ffbd5e',
            red      = '#ff6e5e',
            violet   = '#bd5eff',
            yellow   = '#f1ff5e',
        }
        local colors = cyberdream
        local conditions = {
            buffer_not_empty = function()
                return vim.fn.empty(vim.fn.expand "%:t") ~= 1
            end,
            hide_in_width = function()
                return vim.fn.winwidth(0) > 80
            end,
            check_git_workspace = function()
                local filepath = vim.fn.expand "%:p:h"
                local gitdir = vim.fn.finddir(".git", filepath .. ";")
                return gitdir and #gitdir > 0 and #gitdir < #filepath
            end,
        }
        local config = {
            options = {
                disabled_filetypes = {
                    "NeogitStatus",
                    "snacks_dashboard",
                    "oil",
                    "ministarter",
                    "fzf",
                },
                component_separators = "",
                section_separators = "",
                theme = {
                    normal = { c = { fg = colors.fg, bg = colors.bg } },
                    inactive = { c = { fg = colors.fg, bg = colors.bg } },
                },
            },
            sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_y = {},
                lualine_z = {},
                lualine_c = {},
                lualine_x = {},
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_y = {},
                lualine_z = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
            },
        }
        local function ins_left(component)
            table.insert(config.sections.lualine_c, component)
        end
        local function ins_right(component)
            table.insert(config.sections.lualine_x, component)
        end
        ins_left {
            function()
                return ""
            end,
            color = function()
                local mode_color = {
                    n = colors.blue,
                    i = colors.red,
                    v = colors.green,
                    ["\22"] = colors.green,
                    V = colors.green,
                    c = colors.magenta,
                    no = colors.red,
                    s = colors.orange,
                    S = colors.orange,
                    ["\19"] = colors.orange,
                    ic = colors.yellow,
                    R = colors.violet,
                    Rv = colors.violet,
                    cv = colors.red,
                    ce = colors.red,
                    r = colors.cyan,
                    rm = colors.cyan,
                    ["r?"] = colors.cyan,
                    ["!"] = colors.red,
                    t = colors.red,
                }
                return { bg = mode_color[vim.fn.mode()] }
            end,
            padding = { left = 0, right = 1 },
        }
        ins_left {
            "mode",
            color = function()
                local mode_color = {
                    n = colors.blue,
                    i = colors.red,
                    v = colors.green,
                    ["\22"] = colors.green,
                    V = colors.green,
                    c = colors.magenta,
                    no = colors.red,
                    s = colors.orange,
                    S = colors.orange,
                    ["\19"] = colors.orange,
                    ic = colors.yellow,
                    R = colors.violet,
                    Rv = colors.violet,
                    cv = colors.red,
                    ce = colors.red,
                    r = colors.cyan,
                    rm = colors.cyan,
                    ["r?"] = colors.cyan,
                    ["!"] = colors.red,
                    t = colors.red,
                }
                return { bg = mode_color[vim.fn.mode()], fg = colors.bg }
            end,
            padding = { left = 1, right = 1 },
        }
        ins_left {
            "branch",
            icon = "",
            color = { fg = colors.violet, gui = "bold" },
            padding = { left = 1, right = 1 },
        }
        ins_left {
            "diagnostics",
            sources = { "nvim_diagnostic" },
            symbols = { error = " ", warn = " ", info = " " },
            diagnostics_color = {
                error = { fg = colors.red },
                warn = { fg = colors.yellow },
                info = { fg = colors.cyan },
            },
        }
        ins_left {
            "filename",
            cond = conditions.buffer_not_empty,
            color = { fg = colors.fg, gui = "bold" },
        }
        ins_left {
            function()
                return "%="
            end,
        }
        ins_right {
            "filetype",
            icons_enabled = true,
            color = { gui = "italic" },
        }
        ins_right { "location" }
        ins_right { "progress", color = { fg = colors.fg, gui = "bold" } }
        ins_right {
            function()
                return "▊"
            end,
            color = function()
                local mode_color = {
                    n = colors.blue,
                    i = colors.red,
                    v = colors.green,
                    ["\22"] = colors.green,
                    V = colors.green,
                    c = colors.magenta,
                    no = colors.red,
                    s = colors.orange,
                    S = colors.orange,
                    ["\19"] = colors.orange,
                    ic = colors.yellow,
                    R = colors.violet,
                    Rv = colors.violet,
                    cv = colors.red,
                    ce = colors.red,
                    r = colors.cyan,
                    rm = colors.cyan,
                    ["r?"] = colors.cyan,
                    ["!"] = colors.red,
                    t = colors.red,
                }
                return { fg = mode_color[vim.fn.mode()] }
            end,
            padding = { left = 1 },
        }
        lualine.setup(config)
    end,
}
