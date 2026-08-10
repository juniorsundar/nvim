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
vim.keymap.set("n", "<CR>", function()
    require("buffers.grep").nav_to_match()
end, { buffer = bufnr, silent = true, desc = "Jump to grep match" })

vim.keymap.set("n", "za", function()
    require("buffers.grep").toggle_context()
end, { buffer = bufnr, silent = true, desc = "Toggle grep context" })

vim.keymap.set("n", "zA", function()
    require("buffers.grep").toggle_context()
end, { buffer = bufnr, silent = true, desc = "Toggle grep context" })

vim.keymap.set("n", "z+", function()
    require("buffers.grep").grow_context()
end, { buffer = bufnr, silent = true, desc = "Grow grep context (+3)" })

vim.keymap.set("n", "z-", function()
    require("buffers.grep").shrink_context()
end, { buffer = bufnr, silent = true, desc = "Shrink grep context (-3)" })

vim.keymap.set("n", "zr", function()
    require("buffers.grep").expand_all()
end, { buffer = bufnr, silent = true, desc = "Expand all grep context" })

vim.keymap.set("n", "zm", function()
    require("buffers.grep").collapse_all()
end, { buffer = bufnr, silent = true, desc = "Collapse all grep context" })

vim.keymap.set("n", "zR", function()
    require("buffers.grep").expand_all()
end, { buffer = bufnr, silent = true, desc = "Expand all grep context" })

vim.keymap.set("n", "zM", function()
    require("buffers.grep").collapse_all()
end, { buffer = bufnr, silent = true, desc = "Collapse all grep context" })

vim.keymap.set("n", "<C-c><C-c>", function()
    require("buffers.grep").apply_edits "direct"
end, { buffer = bufnr, silent = true, desc = "Apply grep edits (Direct)" })

vim.keymap.set("n", "<C-c><C-s>", function()
    require("buffers.grep").apply_edits "conflict"
end, { buffer = bufnr, silent = true, desc = "Apply grep edits (Conflict Markers)" })

vim.keymap.set("n", "<C-c><C-r>", function()
    require("buffers.grep").refresh_content()
end, { buffer = bufnr, silent = true, desc = "Refresh content from disk" })

vim.keymap.set("n", "q", function()
    require("buffers.grep").kill_buffer()
end, { buffer = bufnr, silent = true, desc = "Kill buffer" })

vim.keymap.set("n", "g?", function()
    require("buffers.grep").show_help(bufnr)
end, { buffer = bufnr, silent = true, desc = "Show grep buffer keymap help" })

require("buffers.grep").highlight_buffer(bufnr)

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = bufnr,
    callback = function()
        require("buffers.grep").highlight_buffer(bufnr)
    end,
})
