local M = require "minibuffer"
local builtin = require "minibuffer.providers.builtin"
local lsp = require "minibuffer.providers.lsp"
local files = require "minibuffer.providers.files"

vim.keymap.set("n", "<A-x>", builtin.commands, { desc = "Command Palette" })

vim.keymap.set("n", "<C-x>r", lsp.references, { desc = "LSP References" })
vim.keymap.set("n", "<C-x>d", lsp.definitions, { desc = "LSP Definitions" })
vim.keymap.set("n", "<C-x>b", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<C-x>f", files.files, { desc = "Files" })
vim.keymap.set("n", "<C-x>t", files.live_grep, { desc = "Files" })

return M
