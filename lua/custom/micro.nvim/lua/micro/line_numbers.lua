-- Owns each window's line-number state; `dynamic` switches to absolute numbers in insert mode.
local M = {}

local defaults = {
    dynamic = false,
}
local config = defaults

local function inserting()
    return vim.fn.mode():find "^i" ~= nil
end

-- Hide relative numbers for insert mode, remembering to restore only what we hid.
local function suspend()
    if vim.wo.relativenumber then
        vim.w.micro_relnum_suspended = true
        vim.wo.relativenumber = false
    end
end

local function restore()
    if vim.w.micro_relnum_suspended and not inserting() then
        vim.w.micro_relnum_suspended = nil
        vim.wo.relativenumber = true
    end
end

--- Show or hide line numbers in the current window; both options always move together.
function M.toggle()
    local on = not vim.wo.number
    vim.w.micro_relnum_suspended = nil
    vim.wo.number = on
    vim.wo.relativenumber = on
    if on and config.dynamic and inserting() then
        suspend()
    end
    vim.notify("Setting 'Line Numbers' to " .. tostring(on), vim.log.levels.INFO)
end

function M.setup(opts)
    config = vim.tbl_deep_extend("force", defaults, opts or {})
    local group = vim.api.nvim_create_augroup("MicroLineNumbers", { clear = true })
    if config.dynamic then
        vim.api.nvim_create_autocmd("InsertEnter", { group = group, callback = suspend })
        vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, { group = group, callback = restore })
    end
end

return M
