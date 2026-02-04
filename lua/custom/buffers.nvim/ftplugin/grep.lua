if vim.b.did_ftplugin then
    return
end
vim.b.did_ftplugin = 1

local bufnr = vim.api.nvim_get_current_buf()

-- Set buffer options
vim.bo[bufnr].buftype = "nofile"
vim.bo[bufnr].swapfile = false
vim.bo[bufnr].bufhidden = "hide"
vim.bo[bufnr].synmaxcol = 300

-- Keymaps
-- <CR> to jump to match
vim.keymap.set("n", "<CR>", function()
    require("buffers.grep").nav_to_match()
end, { buffer = bufnr, silent = true, desc = "Jump to grep match" })

-- Trigger Highlighting
require("buffers.grep").highlight_buffer(bufnr)

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = bufnr,
    callback = function()
        require("buffers.grep").highlight_buffer(bufnr)
    end,
})
