MiniDeps.now(function()
    MiniDeps.add { source = "webhooked/kanso.nvim" }
    require("kanso").setup {
        bold = true,
        italics = true,
        compile = false,
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = {},
        typeStyle = {},
        transparent = false,
        dimInactive = false,
        terminalColors = true,
        colors = {
            palette = {},
            theme = { zen = {}, pearl = {}, ink = {}, all = {} },
        },
        overrides = function(colors)
            return {}
        end,
        background = {
            dark = "ink",
            light = "pearl",
        },
        foreground = "default",
        minimal = false,
    }
    vim.cmd "colorscheme kanso"
end)
