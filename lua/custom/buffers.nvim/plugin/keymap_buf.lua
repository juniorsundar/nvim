-- :Keymap [mode]
-- Opens an ephemeral keymap buffer showing all keymaps for the given mode
-- (default: normal mode) plus context-aware actions based on cursor position.
--
-- Examples:
--   :Keymap       -> normal mode keymaps
--   :Keymap n     -> normal mode keymaps (explicit)
--   :Keymap i     -> insert mode keymaps
--   :Keymap v     -> visual mode keymaps
vim.api.nvim_create_user_command("Keymap", function(opts)
    local mode = (opts.args ~= "") and opts.args or "n"
    local source_bufnr = vim.api.nvim_get_current_buf()
    local source_winid = vim.api.nvim_get_current_win()

    require("buffers.keymap").create_buffer {
        mode = mode,
        source_bufnr = source_bufnr,
        source_winid = source_winid,
    }
end, {
    nargs = "?",
    desc = "Open contextual keymap buffer",
    complete = function()
        return { "n", "i", "v", "x", "s", "o", "c", "t" }
    end,
})
