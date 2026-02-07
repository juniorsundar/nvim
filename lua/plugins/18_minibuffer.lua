local M = require "minibuffer"
local builtin = require "minibuffer.providers.builtin"
local lsp = require "minibuffer.providers.lsp"
local files = require "minibuffer.providers.files"

vim.keymap.set("n", "<leader>:", builtin.commands, { desc = "Command Palette" })
vim.keymap.set("n", "<leader>Fr", builtin.old_files, { desc = "Recent File" })
vim.keymap.set("n", "<leader>Lr", lsp.references, { desc = "LSP References" })
vim.keymap.set("n", "<leader>Ld", lsp.definitions, { desc = "LSP Definitions" })
vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>Ff", files.files, { desc = "Files" })
vim.keymap.set("n", "<leader>Ft", files.live_grep, { desc = "Text" })

return M
