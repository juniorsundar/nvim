MiniDeps.add { source = "folke/trouble.nvim" }

require("trouble").setup()
vim.keymap.set("n", "<leader>LWd", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Workspace Diagnostics" })
vim.keymap.set("n", "<leader>LDd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics" })
vim.keymap.set(
    "n",
    "<leader>LDa",
    "<cmd>Trouble lsp toggle focus=true win={type='split', position='bottom'}<cr>",
    { desc = "LSP All" }
)
