require("micro.pack").add {
    src = "gh:delphinus/md-render.nvim",
}
vim.keymap.set("n", "<leader>Mp", "<Plug>(md-render-preview)", { desc = "Markdown preview (toggle)" })
vim.keymap.set("n", "<leader>Mt", "<Plug>(md-render-preview-tab)", { desc = "Markdown preview in tab (toggle)" })
