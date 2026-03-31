vim.pack.add { gh "tpope/vim-fugitive" }

vim.keymap.set("n", "<leader>Gg", "<cmd>tab Git<cr>", { desc = "Fugitive", noremap = false, silent = true })
vim.keymap.set("n", "<leader>G", "", { desc = "Git", noremap = false, silent = true })
