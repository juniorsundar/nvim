return {
    "stevearc/oil.nvim",
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("oil").setup {
            columns = {
                "size",
                "icon",
            },
            view_options = {
                show_hidden = true,
            },
        }
    end,
}
