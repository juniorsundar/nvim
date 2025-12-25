local Snacks = require "snacks"

local M = {}

---@class LspConfigItem
---@field name string
---@field file string
---@field active boolean
---@field config table

---@return LspConfigItem[]
local function get_lsp_configs()
    local configs = {}
    local seen = {}
    local files = vim.api.nvim_get_runtime_file("after/lsp/*.lua", true)

    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        if not seen[name] then
            seen[name] = true
            table.insert(configs, {
                name = name,
                file = file,
                active = false,
            })
        end
    end
    table.sort(configs, function(a, b)
        return a.name < b.name
    end)
    return configs
end

function M.lsp_picker()
    local items = {}
    local configs = get_lsp_configs()

    for _, config in ipairs(configs) do
        local clients = vim.lsp.get_clients { name = config.name }
        local is_active = #clients > 0

        table.insert(items, {
            text = config.name,
            name = config.name,
            file = config.file,
            active = is_active,
            preview = {
                file = config.file,
                ft = "lua",
            },
        })
    end

    Snacks.picker {
        title = "LSP Servers",
        items = items,
        format = function(item, _)
            local status_icon = item.active and "●" or "○"
            local status_hl = item.active and "DiagnosticOk" or "Comment"
            return {
                { status_icon .. " ", status_hl },
                { item.text, "" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if item.active then
                local clients = vim.lsp.get_clients { name = item.name }
                for _, client in ipairs(clients) do
                    vim.lsp.stop_client(client.id)
                end
                vim.notify("Stopped LSP: " .. item.name, vim.log.levels.INFO)
            else
                local ok, config = pcall(dofile, item.file)
                if not ok then
                    vim.notify("Failed to load config for " .. item.name .. ": " .. config, vim.log.levels.ERROR)
                    return
                end

                config.name = config.name or item.name

                if not config.root_dir and config.root_markers then
                    config.root_dir = vim.fs.root(0, config.root_markers) or vim.fn.getcwd()
                end

                -- Call vim.lsp.start
                local client_id = vim.lsp.start(config)
                if client_id then
                    vim.notify("Started LSP: " .. item.name, vim.log.levels.INFO)
                else
                    vim.notify("Failed to start LSP: " .. item.name, vim.log.levels.ERROR)
                end
            end
        end,
    }
end

return M
