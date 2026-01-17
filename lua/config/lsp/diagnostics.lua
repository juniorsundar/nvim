local momentary_virtual_lines_active = false
vim.keymap.set("n", "<C-w>d", function()
    vim.diagnostic.config { virtual_lines = { current_line = true } }
    momentary_virtual_lines_active = true
end, { desc = "Show diagnostic virtual lines", remap = true })

local augroup = vim.api.nvim_create_augroup("MomentaryVirtualLines", { clear = true })

vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup,
    pattern = "*", -- Apply in all buffers
    callback = function()
        if momentary_virtual_lines_active then
            local current_config = vim.diagnostic.config().virtual_lines
            if type(current_config) == "table" and current_config.current_line == true then
                vim.diagnostic.config { virtual_lines = false }
            end
            momentary_virtual_lines_active = false
        end
    end,
})

vim.diagnostic.config {
    virtual_lines = false,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰅙",
            [vim.diagnostic.severity.INFO] = "󰋼",
            [vim.diagnostic.severity.HINT] = "󰌵",
            [vim.diagnostic.severity.WARN] = "",
        },
        linehl = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.WARN] = "",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
            [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
            [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
            [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
        },
    },
    underline = true,
    update_in_insert = false,
    virtual_text = false,
}
