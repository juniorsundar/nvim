local remember_folds = vim.api.nvim_create_augroup("remember_folds", { clear = true })
vim.api.nvim_create_autocmd("BufWinLeave", {
    group = remember_folds,
    pattern = "*.py",
    command = "mkview"
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = remember_folds,
    pattern = "*.py",
    command = "silent! loadview"
})
