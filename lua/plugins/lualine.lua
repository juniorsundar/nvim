return {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    config = function()
        require("lualine").setup {
            options = {
                icons_enabled = true,
                theme = "onedark",
                component_separators = { left = " ", right = " " },
                section_separators = { left = " ", right = " " },
                disabled_filetypes = {
                    "NeogitStatus",
                    "snacks_dashboard",
                    "ministarter",
                    "fzf",
                    "neo-tree",
                },
                ignore_focus = {},
                always_divide_middle = true,
                always_show_tabline = true,
                globalstatus = false,
                refresh = {
                    statusline = 100,
                    tabline = 100,
                    winbar = 100,
                },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diagnostics" },
                lualine_c = { "filename" },
                lualine_x = { "filetype" },
                lualine_y = { "location" },
                lualine_z = { { "tabs", use_mode_colors = true } },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = { "oil", "quickfix", "mason", "man", "lazy" },
        }
    end,
}
