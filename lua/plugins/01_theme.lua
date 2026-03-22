MiniDeps.now(function()
    MiniDeps.add { source = "navarasu/onedark.nvim" }

    require("onedark").setup {
        style = "dark",
        highlights = {
            ["DiagnosticHint"] = { fg = "$green" },
            ["DiagnosticUnderlineHint"] = { sp = "$green" },
            ["CursorLine"] = { bg = "$bg0" },
            ["Folded"] = { bg = "$bg0" },
        },
    }
    require("onedark").load()
end)
