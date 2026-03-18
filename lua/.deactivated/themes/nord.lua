MiniDeps.now(function()
    MiniDeps.add { source = "AlexvZyl/nordic.nvim" }
    require("nordic").setup {}
    vim.cmd.colorscheme "nordic"
end)
