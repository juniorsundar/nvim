return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                custom_highlights = function(colors)
                    return {
                        WhichKeyFloat = { fg = colors.base, bg = colors.base },
                    }
                end,
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    treesitter = true,
                    alpha = true,
                    barbar = true,
                    flash = true,
                    markdown = true,
                    neogit = true,
                    treesitter_context = true,
                    lsp_saga = true,
                    lsp_trouble = true,
                    diffview = true,
                    which_key = true,
                    mason = true,
                    noice = true,
                    notify = true,
                    native_lsp = {
                        enabled = true,
                    },
                    mini = true,
                },
            })
            vim.cmd.colorscheme("catppuccin-frappe")
        end,
    },
    {
        "nyoom-engineering/oxocarbon.nvim"
    },
    {
        "folke/tokyonight.nvim",
    },
    {
        "nvim-tree/nvim-web-devicons",
    },
}
