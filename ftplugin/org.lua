vim.opt.conceallevel = 2
vim.opt.concealcursor = 'nc'
vim.opt.scrolloff = 999

vim.api.nvim_create_autocmd("InsertEnter", {
    pattern = "*.org",
    group = vim.api.nvim_create_augroup("OrgWrapOn", { clear = true }),
    callback = function(_)
        vim.cmd("set wrap")
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = "*.org",
    group = vim.api.nvim_create_augroup("OrgWrapOff", { clear = true }),
    callback = function(_)
        vim.cmd("set nowrap")
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.org",
    group = vim.api.nvim_create_augroup("OrgWrapOffBuf", { clear = true }),
    callback = function(_)
        vim.cmd("set nowrap")
    end,
})

vim.api.nvim_create_autocmd("BufLeave", {
    pattern = "*.org",
    group = vim.api.nvim_create_augroup("OrgWrapOnBuf", { clear = true }),
    callback = function(_)
        vim.cmd("set wrap")
    end,
})

