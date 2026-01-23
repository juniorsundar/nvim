MiniDeps.now(function()
    MiniDeps.add { source = "mistweaverco/vhs-era-theme.nvim" }
    require("vhs-era-theme").setup {
        italic_comments = true,
        disable_cache = false,
        hot_reload = false,
    }
    vim.cmd.colorscheme "vhs-era-theme"
end)
