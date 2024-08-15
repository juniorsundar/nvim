vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

local remember_folds = vim.api.nvim_create_augroup("remember_folds", { clear = true })
vim.api.nvim_create_autocmd("BufWinLeave", {
    group = remember_folds,
    pattern = "*.go",
    command = "mkview"
})
--
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = remember_folds,
    pattern = "*.go",
    command = "silent! loadview"
})
