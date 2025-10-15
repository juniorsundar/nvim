return {
    "stevearc/oil.nvim",
    lazy = false,
    config = function()
        require("oil").setup({
            columns = {
                "permissions",
                "mtime",
                "size",
                "icon",
            },
            view_options = {
                show_hidden = true,
            },
            confirmation = {
                border = "rounded"
            }
        })
        vim.keymap.set("n", "<leader>o", "<cmd>Oil<cr>", { desc = "LSP", noremap = false, silent = true })
    end
}
