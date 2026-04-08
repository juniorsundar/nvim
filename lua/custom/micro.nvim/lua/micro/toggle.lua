local M = {}

local default = {
    toggle_prefix = "<localleader>T",
    toggle = {
        line_numbers = { modes = { "n" }, key = "n" },
        lsp_inlay_hints = { modes = { "n" }, key = "i" },
        lsp_code_lens = { modes = { "n" }, key = "c" },
    },
}

local broadcast = function(toggle, state)
    vim.notify("Setting '" .. toggle .. "' to " .. tostring(state), vim.log.levels.INFO)
end

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

            broadcast("Line Numbers", not number)
            vim.api.nvim_set_option_value("number", not number, { win = current_win })
            vim.api.nvim_set_option_value("relativenumber", not relativenumber, { win = current_win })
        end,
        { desc = "Line Numbers" }
    )

    vim.keymap.set(
        default.toggle.lsp_inlay_hints.modes,
        default.toggle_prefix .. default.toggle.lsp_inlay_hints.key,
        function()
            broadcast("LSP Inlay Hints", not vim.lsp.inlay_hint.is_enabled())
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end,
        { desc = "LSP Inlay Hints" }
    )

    vim.keymap.set(
        default.toggle.lsp_code_lens.modes,
        default.toggle_prefix .. default.toggle.lsp_code_lens.key,
        function()
            if vim.lsp.codelens.is_enabled() then
                broadcast("LSP CodeLens", false)
                vim.lsp.codelens.enable(false)
            else
                broadcast("LSP CodeLens", true)
                vim.lsp.codelens.enable(true)
            end
        end,
        { desc = "LSP CodeLens" }
    )
end

return M
