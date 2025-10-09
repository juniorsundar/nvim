return {
    "stevearc/oil.nvim",
    opts = {
        columns = {
            "permissions",
            "mtime",
            "size",
            "icon",
        },
        view_options = {
            show_hidden = true,
        },
    },
    keys = {
        { "<leader>o", mode = { "n" }, "<cmd>Oil<cr>", desc = "Oil" }
    }
}
