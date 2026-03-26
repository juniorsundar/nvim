local M = {}

local default = {
    toggle_prefix = "<localleader>T",
    toggle = {
        line_numbers = { modes = { "n" }, key = "n" },
        lsp_inlay_hints = { modes = { "n" }, key = "i" },
    },
}

function M.setup(opts)
    default = vim.tbl_deep_extend("force", default, opts or {})

    vim.keymap.set({ "n", "v" }, default.toggle_prefix, "", { desc = "Toggle", noremap = false, silent = true })
    vim.keymap.set(
        default.toggle.line_numbers.modes,
        default.toggle_prefix .. default.toggle.line_numbers.key,
        function()
            local current_win = vim.api.nvim_get_current_win()
            local number = vim.api.nvim_get_option_value("number", { win = current_win })
            local relativenumber = vim.api.nvim_get_option_value("relativenumber", { win = current_win })

            vim.api.nvim_set_option_value("number", not number, { win = current_win })
            vim.api.nvim_set_option_value("relativenumber", not relativenumber, { win = current_win })
        end,
        { desc = "Line Numbers" }
    )

    vim.keymap.set(
        default.toggle.lsp_inlay_hints.modes,
        default.toggle_prefix .. default.toggle.lsp_inlay_hints.key,
        function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end,
        { desc = "LSP Inlay Hints" }
    )
end

return M
