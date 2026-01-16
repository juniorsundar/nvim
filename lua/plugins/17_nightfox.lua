MiniDeps.now(function()
    MiniDeps.add { source = "EdenEast/nightfox.nvim" }
    local palette = require("nightfox.palette").load "carbonfox"
    require("nightfox").setup {
        options = {
            compile_path = vim.fn.stdpath "cache" .. "/nightfox",
            compile_file_suffix = "_compiled",
            transparent = false,
            terminal_colors = true,
            dim_inactive = false,
            module_default = true,
            colorblind = {
                enable = false,
                simulate_only = false,
                severity = {
                    protan = 0,
                    deutan = 0,
                    tritan = 0,
                },
            },
            styles = {
                comments = "italic",
                conditionals = "NONE",
                constants = "NONE",
                functions = "NONE",
                keywords = "NONE",
                numbers = "NONE",
                operators = "NONE",
                strings = "NONE",
                types = "NONE",
                variables = "NONE",
            },
            inverse = {
                match_paren = false,
                visual = false,
                search = false,
            },
            modules = {},
        },
        palettes = {},
        specs = {},
        groups = {
            all = {
                SnacksPickerListBorder = { fg = palette.fg0 },
                SnacksPickerPreviewBorder = { fg = palette.fg0 },
                SnacksPickerInputBorder = { fg = palette.fg0 },
                SnacksPickerBoxBorder = { fg = palette.fg0 },
                SnacksPickerList = { fg = palette.fg0 },
                SnacksPickerPreview = { fg = palette.fg0 },
                SnacksPickerInput = { fg = palette.fg0 },
                SnacksPickerBox = { fg = palette.fg0 },
                SnacksPickerCol = { fg = palette.fg0 },
                StatusLine = { bg = palette.bg1 },
                StatusLineNC = { bg = palette.bg1 },
                BlinkCmpMenu = { fg = palette.fg0, bg = palette.bg2 },
                BlinkCmpMenuBorder = { fg = palette.fg0, bg = palette.bg2 },
                BlinkCmpSignatureHelp = { fg = palette.fg0, bg = palette.bg2 },
                BlinkCmpSignatureHelpBorder = { fg = palette.fg0, bg = palette.bg2 },
                BlinkCmpDoc = { fg = palette.fg0, bg = palette.bg2 },
                BlinkCmpDocBorder = { fg = palette.fg0, bg = palette.bg2 },
                BlinkCmpKind = { fg = palette.fg0 },
                BlinkCmpDocSeparator = { fg = palette.fg0, bg = palette.bg2 },
                FloatBorder = { bg = palette.bg2 },
                NormalFloat = { bg = palette.bg2 },
            },
        },
    }
    -- vim.cmd.colorscheme "carbonfox"
end)
