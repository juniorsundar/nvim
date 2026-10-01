vim.pack.add { "https://github.com/delphinus/md-render.nvim" }
vim.keymap.set("n", "<leader>Mp", "<cmd>vert MdRender split<cr>", { desc = "Markdown preview (toggle)" })
