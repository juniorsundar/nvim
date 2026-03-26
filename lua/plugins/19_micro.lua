require("micro").setup {
    statusline = {
        enabled = true,
        ignored = {
            names = {
                ["[Lazygit]"] = true,
            },
        },
    },
}

vim.keymap.set("n", "<leader>Lk", function()
    vim.Micro.eldoc()
end, { desc = "Hover", noremap = false, silent = true })
vim.keymap.set("n", "<M-j>", function()
    require("micro.hover").scroll(1)
end, { desc = "Scroll eldoc down" })
vim.keymap.set("n", "<M-k>", function()
    require("micro.hover").scroll(-1)
end, { desc = "Scroll eldoc up" })
