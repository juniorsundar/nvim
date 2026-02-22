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

    vim.api.nvim_create_autocmd("InsertLeave", { -- Using InsertLeave
        group = augroup,
        pattern = "*",
        callback = function()
            if vim.w.did_disable_relnum == true then
                vim.wo.relativenumber = true
                vim.w.did_disable_relnum = nil -- Clear the flag
            end
        end,
    })

    -- Autocommand to fix state on window focus
    vim.api.nvim_create_autocmd("WinEnter", {
        group = augroup,
        pattern = "*",
        callback = function()
            -- Check if we are in normal mode AND the flag is still lingering
            if vim.fn.mode() == "n" and vim.w.did_disable_relnum == true then
                -- This means InsertLeave failed to restore relativenumber. Fix it now.
                vim.wo.relativenumber = true
                vim.w.did_disable_relnum = nil
            end
        end,
    })
end

return M
