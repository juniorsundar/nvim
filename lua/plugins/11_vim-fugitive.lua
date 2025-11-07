MiniDeps.add { source = "tpope/vim-fugitive" }

vim.keymap.set("n", "<leader>Gg", "<cmd>tab Git<cr>", { desc = "Fugitive", noremap = false, silent = true })
