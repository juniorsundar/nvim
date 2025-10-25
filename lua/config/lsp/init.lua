require "config.lsp.keymaps"
require "config.lsp.hover"
require "config.lsp.breadcrumbs"

local mason_bin = vim.fn.stdpath "data" .. "/mason/bin"
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
vim.keymap.set("n", "<leader>m", function()
    require("mason.ui").open()
end, { desc = "Mason", noremap = false, silent = true })
