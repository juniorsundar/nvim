local neorg_loaded, neorg = pcall(require, "neorg.core")
assert(neorg_loaded, "Neorg is not loaded - please make sure to load Neorg first")

vim.api.nvim_create_autocmd("InsertEnter", {
    pattern = "*.norg",
    group = vim.api.nvim_create_augroup("NeorgWrapOn", { clear = true }),
    callback = function(_)
        vim.cmd "set wrap"
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = "*.norg",
    group = vim.api.nvim_create_augroup("NeorgWrapOff", { clear = true }),
    callback = function(_)
        local current_workspace = neorg.modules.get_module("core.dirman").get_current_workspace()
        if current_workspace[1] == "default" then
            vim.cmd "set nowrap"
        end
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.norg",
    group = vim.api.nvim_create_augroup("NeorgWrapOffBuf", { clear = true }),
    callback = function(_)
        local current_workspace = neorg.modules.get_module("core.dirman").get_current_workspace()
        if current_workspace[1] == "default" then
            vim.cmd "set nowrap"
        end
    end,
})

vim.api.nvim_create_autocmd("BufLeave", {
    pattern = "*.norg",
    group = vim.api.nvim_create_augroup("NeorgWrapOnBuf", { clear = true }),
    callback = function(_)
        vim.cmd "set wrap"
    end,
})

local remember_folds = vim.api.nvim_create_augroup("remember_folds", { clear = true })
vim.api.nvim_create_autocmd("BufWinLeave", {
    group = remember_folds,
    pattern = "*.norg",
    command = "mkview",
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = remember_folds,
    pattern = "*.norg",
    command = "silent! loadview",
})

vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

vim.opt.conceallevel = 2
vim.opt.scrolloff = 0
vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldcolumn = "0"
