return {
    "akinsho/bufferline.nvim",
    enabled = false,
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
        require("bufferline").setup {
            options = {
                themable = true,
                indicator = {
                    icon = "▎",
                    style = "icon",
                },
                separator_style = "thick",
                diagnostics = "nvim_lsp",
            },
        }
    end,
}
