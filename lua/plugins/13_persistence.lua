MiniDeps.add { source = "folke/persistence.nvim" }

require("persistence").setup()
vim.keymap.set("n", "<leader>q", "", { desc = "Persistence" })
vim.keymap.set("n", "<leader>qs", function()
    require("persistence").load()
end, { desc = "Load Session for CWD" })
vim.keymap.set("n", "<leader>qS", function()
    require("persistence").select()
end, { desc = "Select Session" })
vim.keymap.set("n", "<leader>ql", function()
    require("persistence").load { last = true }
end, { desc = "Load Last Session" })
vim.keymap.set("n", "<leader>qd", function()
    require("persistence").stop()
end, { desc = "Stop Persistence on Exit" })
