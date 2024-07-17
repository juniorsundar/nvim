return {
    "stevearc/oil.nvim",
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
