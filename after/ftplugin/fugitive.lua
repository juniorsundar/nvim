local fugitive_augroup = vim.api.nvim_create_augroup("FugitiveSettings", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
    group = fugitive_augroup,
    pattern = "fugitive://*",
    callback = function()
        local fugitive_window = vim.api.nvim_get_current_win()
        vim.api.nvim_set_option_value("number", false, { win = fugitive_window })
        vim.api.nvim_set_option_value("relativenumber", false, { win = fugitive_window })
    end,
})

vim.api.nvim_create_autocmd("BufLeave", {
    group = fugitive_augroup,
    pattern = "fugitive://*",
    callback = function()
        local exit_window = vim.api.nvim_get_current_win()
        vim.api.nvim_set_option_value("number", true, { win = exit_window })
        vim.api.nvim_set_option_value("relativenumber", true, { win = exit_window })
    end,
})
