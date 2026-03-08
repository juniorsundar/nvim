local keymap = require "buffers.keymap"

local function open_keymap_buf()
    local mode = vim.fn.mode()
    local source_bufnr = vim.api.nvim_get_current_buf()
    local source_winid = vim.api.nvim_get_current_win()

    local mode_char = mode:sub(1, 1)

    keymap.create_buffer {
        mode = mode_char,
        source_bufnr = source_bufnr,
        source_winid = source_winid,
    }
end

vim.keymap.set({ "n", "v", "x", "s", "o", "i", "t" }, "<M-x><M-h>", open_keymap_buf, {
    desc = "Keymap Buffer",
    silent = true,
})

return keymap
