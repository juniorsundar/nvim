local M = {}

local defaults = {
    statusline = { enabled = true },
    ["toggle-lnum"] = { enabled = true },
    ["treesit-navigator"] = { enabled = true },
    breadcrumbs = { enabled = false },
    folds = { enabled = true },
    hover = { enabled = true },
    signature = { enabled = true },
}

function M.setup(opts)
    if not vim.Micro then
        vim.Micro = {}
    end

    local config = vim.tbl_deep_extend("force", defaults, opts or {})

    for module_name, module_opts in pairs(config) do
        local enabled = module_opts == true or (type(module_opts) == "table" and module_opts.enabled ~= false)

        if enabled then
            local ok, mod = pcall(require, "micro." .. module_name)
            if not ok then
                vim.notify(
                    "micro.nvim: failed to load module '" .. module_name .. "'\n" .. tostring(mod),
                    vim.log.levels.ERROR
                )
            elseif type(mod.setup) == "function" then
                local call_opts = type(module_opts) == "table" and module_opts or {}
                mod.setup(call_opts)
            end
        end
    end
end

return M
