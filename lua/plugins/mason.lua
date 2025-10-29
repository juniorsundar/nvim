MiniDeps.add({ source = "mason-org/mason.nvim" })
require("mason").setup()

local mason_bin = vim.fn.stdpath "data" .. "/mason/bin"
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
vim.keymap.set("n", "<leader>m", function() require("mason.ui").open() end,
    { desc = "Mason", noremap = false, silent = true })
