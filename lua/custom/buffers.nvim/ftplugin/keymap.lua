if vim.b.did_ftplugin then
    return
end
vim.b.did_ftplugin = 1

local bufnr = vim.api.nvim_get_current_buf()

-- Buffer options: nofile, ephemeral (wipe on hide), read-only
vim.bo[bufnr].buftype = "nofile"
vim.bo[bufnr].swapfile = false
vim.bo[bufnr].bufhidden = "wipe"
vim.bo[bufnr].modifiable = false

vim.keymap.set("n", "<CR>", function()
    require("buffers.keymap").execute_keymap()
end, { buffer = bufnr, silent = true, desc = "Execute keymap / action" })

vim.keymap.set("n", "<C-c><C-d>", function()
    require("buffers.keymap").nav_to_definition()
end, { buffer = bufnr, silent = true, desc = "Jump to keymap definition" })

vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
end, { buffer = bufnr, silent = true, desc = "Close keymap buffer" })

vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
end, { buffer = bufnr, silent = true, desc = "Close keymap buffer" })

require("buffers.keymap").highlight_buffer(bufnr)
