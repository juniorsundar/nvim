MiniDeps.now(function()
    MiniDeps.add { source = "folke/which-key.nvim" }

    vim.o.timeout = true
    vim.o.timeoutlen = 500
    require("which-key.colors").Normal = "NormalFloat"

    require("which-key").setup {
        preset = "classic",
        delay = function(ctx)
            return ctx.plugin and 0 or 1000
        end,
        icons = {
            rules = false,
        },
        win = {
            border = { "─", "─", "─", "", "", "", "", "" },
            padding = { 1, 2 },
            title = true,
            title_pos = "center",
            zindex = 1000,
        },
        layout = {
            width = { min = 20 },
            spacing = 3,
            align = "center",
        },
    }

    local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
    local border_fg = vim.api.nvim_get_hl(0, { name = "FloatBorder" }).fg

    vim.api.nvim_set_hl(0, "WhichKeyNormal", { bg = normal_bg })
    vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = border_fg, bg = normal_bg })
end)
