local M = {}

local defaults = {
    breadcrumbs = { enabled = false },
    dynamic_lnum = { enabled = false },
    folds = { enabled = false },
    follow_mode = { enabled = false },
    hover = { enabled = false },
    pack = { enabled = false },
    quickfix = { enabled = false },
    session = { enabled = false },
    signature = { enabled = false },
    split_suffix = { enabled = false },
    statusline = { enabled = false },
    toggle = { enabled = false },
    treesit_navigator = { enabled = false },
}

function M.setup(opts)
    if not vim.Micro then
        vim.Micro = {}
    end

    local config = vim.tbl_deep_extend("force", defaults, opts or {})

    local subcommands = {}

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

            if type(mod.subcommands) == "table" then
                for name, handler in pairs(mod.subcommands) do
                    subcommands[name] = handler
                end
            end
        end
    end

    vim.api.nvim_create_user_command("Micro", function(opts)
        local args = table.concat(opts.fargs, " ")
        if args == "" then
            vim.notify("Usage: :Micro <subcommand>", vim.log.levels.WARN)
            return
        end

        if subcommands[args] then
            subcommands[args]()
        else
            vim.notify("Unknown Micro subcommand: " .. args, vim.log.levels.WARN)
        end
    end, {
        nargs = "*",
        complete = function(arg_lead, cmd_line, cursor_pos)
            -- Build the partial subcommand from all args so far
            local full_cmd = vim.trim(cmd_line:gsub("^Micro%s+", ""))
            local matches = {}
            for name, _ in pairs(subcommands) do
                if vim.startswith(name, full_cmd) then
                    table.insert(matches, name)
                end
            end
            return matches
        end,
    })
end

return M
