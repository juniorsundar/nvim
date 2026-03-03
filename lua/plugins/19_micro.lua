require("micro").setup()

vim.keymap.set("n", "<leader>Lk", function()
    vim.Micro.eldoc()
end, { desc = "Hover", noremap = false, silent = true })
