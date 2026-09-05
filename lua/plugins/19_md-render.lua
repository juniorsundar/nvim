require("micro.pack").add {
    src = "gh:delphinus/md-render.nvim",
}
vim.keymap.set("n", "<leader>Mp", "<cmd>vert MdRenderSplit<cr>", { desc = "Markdown preview (toggle)" })
