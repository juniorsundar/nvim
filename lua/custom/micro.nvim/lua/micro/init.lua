local M = {}

local defaults = {
    breadcrumbs = { enabled = false },
    dynamic_lnum = { enabled = false },
    folds = { enabled = false },
    follow_mode = { enabled = false },
    hover = { enabled = false },
    quickfix = { enabled = false },
    scratch = { enabled = false },
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

    local function resolve(fargs)
        local node = subcommands
        local consumed = 0

        while consumed < #fargs and type(node) == "table" do
            local rest = table.concat(fargs, " ", consumed + 1)
            local best_name, best_len
            for name in pairs(node) do
                local escaped = name:gsub("(%W)", "%%%1")
                local matched = rest:match("^" .. escaped .. "%s") or rest == name
                if matched and (not best_len or #name > best_len) then
                    best_name, best_len = name, #name
                end
            end
            if not best_name then
                break
            end
            consumed = consumed + #vim.split(best_name, "%s+")
            node = node[best_name]
        end

        return node, consumed
    end

    vim.api.nvim_create_user_command("Micro", function(opts)
        local fargs = opts.fargs
        if #fargs == 0 then
            vim.notify("Usage: :Micro <subcommand>", vim.log.levels.WARN)
            return
        end

        local node, consumed = resolve(fargs)

        if type(node) == "function" then
            node(unpack(fargs, consumed + 1))
        elseif type(node) == "table" then
            local rest = table.concat(fargs, " ", consumed + 1)
            if rest == "" then
                local children = {}
                for name in pairs(node) do
                    table.insert(children, name)
                end
                vim.notify("Available subcommands: " .. table.concat(children, ", "), vim.log.levels.INFO)
            else
                vim.notify("Unknown Micro subcommand: " .. rest, vim.log.levels.WARN)
            end
        else
            vim.notify("Unknown Micro subcommand: " .. table.concat(fargs, " ", consumed + 1), vim.log.levels.WARN)
        end
    end, {
        nargs = "*",
        complete = function(arg_lead, cmd_line)
            local full_cmd = vim.trim(cmd_line:gsub("^Micro%s+", ""))
            local fargs = full_cmd == "" and {} or vim.split(full_cmd, "%s+")

            local node, consumed = resolve(fargs)

            if type(node) ~= "table" then
                return {}
            end

            local rest = table.concat(fargs, " ", consumed + 1)

            local matches = {}
            for name in pairs(node) do
                if vim.startswith(name, rest) then
                    table.insert(matches, name)
                end
            end
            return matches
        end,
    })
end

return M
