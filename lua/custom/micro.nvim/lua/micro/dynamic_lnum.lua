local M = {}

function M.setup(opts)
    local augroup = vim.api.nvim_create_augroup("ToggleRelativeNumberOnInsert", { clear = true })

    vim.api.nvim_create_autocmd("InsertEnter", {
        group = augroup,
        pattern = "*",
        callback = function()
            if vim.wo.number or vim.wo.relativenumber then
                vim.w.did_disable_relnum = true
                vim.wo.relativenumber = false
            else
                vim.w.did_disable_relnum = nil
            end
        end,
    })

    vim.api.nvim_create_autocmd("InsertLeave", {
        group = augroup,
        pattern = "*",
        callback = function()
            if vim.w.did_disable_relnum == true then
                vim.wo.relativenumber = true
                vim.w.did_disable_relnum = nil
            end
        end,
    })

    vim.api.nvim_create_autocmd("WinEnter", {
        group = augroup,
        pattern = "*",
        callback = function()
            if vim.fn.mode() == "n" and vim.w.did_disable_relnum == true then
                vim.wo.relativenumber = true
                vim.w.did_disable_relnum = nil
            end
        end,
    })
end

return M
