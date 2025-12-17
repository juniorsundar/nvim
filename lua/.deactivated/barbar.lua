return {
    "romgrk/barbar.nvim",
    enabled = false,
    dependencies = {
        "lewis6991/gitsigns.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    init = function()
        vim.g.barbar_auto_setup = false
    end,
    opts = {
        icons = {
            gitsigns = {
                added = { enabled = true, icon = "+" },
                changed = { enabled = true, icon = "~" },
                deleted = { enabled = true, icon = "-" },
            },
        },
    },
}
