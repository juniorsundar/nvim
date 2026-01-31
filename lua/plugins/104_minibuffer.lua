local M = require "minibuffer"
local builtin = require "minibuffer.providers.builtin"
local lsp = require "minibuffer.providers.lsp"

vim.keymap.set("n", "<A-x>", builtin.commands, { desc = "Command Palette" })

vim.keymap.set("n", "<C-x>r", lsp.references, { desc = "LSP References" })
vim.keymap.set("n", "<C-x>d", lsp.definitions, { desc = "LSP Definitions" })

return M
