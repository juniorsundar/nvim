require("micro").setup()

vim.keymap.set("n", "<leader>Tk", function()
    vim.Micro.eldoc()
end, { desc = "Hover", noremap = false, silent = true })
