vim.pack.add { "https://github.com/stevearc/oil.nvim" }
require("oil").setup {
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
        border = "solid",
    },
}

vim.keymap.set("n", "<leader>o", function()
    vim.cmd "Oil"
end, { desc = "Oil", noremap = false, silent = true })
