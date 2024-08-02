return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
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
                    grug_far = true,
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
                    nvim_surround = true
                },
            })
        end,
    },
    {
        "scottmckendry/cyberdream.nvim",
        priority = 1000,
        config = function()
            require("cyberdream").setup({
                borderless_telescope = false,
                theme = {
                    variant = "dark",
                    colors = {},
                    highlights = {},
                },
                extensions = {
                    alpha = true,
                    cmp = true,
                    gitsigns = true,
                    grugfar = true,
                    heirline = true,
                    hop = true,
                    lazy = true,
                    mini = true,
                    noice = true,
                    notify = true,
                    telescope = true,
                    treesitter = true,
                    treesittercontext = true,
                    whichkey = true,
                },
            })
            vim.cmd.colorscheme("cyberdream")
        end
    },
    {
        "folke/tokyonight.nvim",
    },
    {
        "nvim-tree/nvim-web-devicons",
    },
}
