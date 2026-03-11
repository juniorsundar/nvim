vim.keymap.set("n", "<localleader>Tn", "", { desc = "Toggle" })

vim.keymap.set("n", "<localleader>Tn", function()
    local current_win = vim.api.nvim_get_current_win()
    local number = vim.api.nvim_get_option_value("number", { win = current_win })
    local relativenumber = vim.api.nvim_get_option_value("relativenumber", { win = current_win })

    vim.api.nvim_set_option_value("number", not number, { win = current_win })
    vim.api.nvim_set_option_value("relativenumber", not relativenumber, { win = current_win })
end, { desc = "Line Numbers" })
