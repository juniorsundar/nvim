MiniDeps.now(function()
    MiniDeps.add { source = "navarasu/onedark.nvim" }

    require("onedark").setup {
        style = "dark",
    }
    require("onedark").load()
end)
