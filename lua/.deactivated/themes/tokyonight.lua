MiniDeps.now(function()
    MiniDeps.add { source = "folke/tokyonight.nvim", name = "catppuccin" }
    require("tokyonight").setup {
        cache = true,
        plugins = {
            all = true,
        },
    }

    vim.cmd [[colorscheme tokyonight]]
end)
