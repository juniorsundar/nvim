require("micro.pack").add { src = "gh:navarasu/onedark.nvim" }

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
