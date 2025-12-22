MiniDeps.add {
    source = "OXY2DEV/markview.nvim",
    hooks = {
        post_checkout = function()
            vim.cmd "TSInstall markdown markdown_inline html latex typst yaml"
        end,
    },
}
