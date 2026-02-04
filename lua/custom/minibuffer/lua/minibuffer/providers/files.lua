local M = {}
local minibuffer = require "minibuffer"
local util = require "minibuffer.util"

function M.files()
    local files_list = {}
    local ignored_dirs = { ".git", ".jj", "node_modules", ".cache" }
    local cmd = { "fd", "-H", "--type", "f" }
    for _, dir in ipairs(ignored_dirs) do
        table.insert(cmd, "--exclude")
        table.insert(cmd, dir)
    end

    local fd_result = vim.system(cmd, { text = true }):wait()
    files_list = vim.split(fd_result.stdout, "\n", { trimempty = true })
    minibuffer.pick(files_list, nil, {
        prompt = "Files > ",
        keymaps = {
            ["<Tab>"] = "toggle_mark",
            ["<CR>"] = "select_entry",
        },
        parser = util.parsers.file,
        on_select = function(selection, data)
            util.jump_to_location(selection, data)
            pcall(vim.cmd, 'normal! g`"')
        end,
    })
end

local current_job = nil

function M.live_grep()
    minibuffer.pick({}, util.jump_to_location, {
        prompt = "Grep > ",
        parser = util.parsers.grep,

        on_change = function(query, update_ui_callback)
            M.run_async_grep(query, update_ui_callback)
        end,
        keymaps = {
            ["<Tab>"] = "toggle_mark",
            ["<CR>"] = "select_entry",
        },
    })
end

function M.run_async_grep(query, update_ui_callback)
    if current_job then
        current_job:kill()
        current_job = nil
    end

    update_ui_callback {}

    if not query or #query < 2 then
        return
    end

    local cmd = { "rg", "--vimgrep", "--smart-case", "--", query }

    local output_lines = {}
    local this_job

    this_job = vim.system(cmd, {
        text = true,
        stdout = function(_, data)
            if data then
                local lines = vim.split(data, "\n", { trimempty = true })
                for _, line in ipairs(lines) do
                    table.insert(output_lines, line)
                end

                vim.schedule(function()
                    if current_job ~= this_job then
                        return
                    end
                    update_ui_callback(output_lines)
                end)
            end
        end,
    })
    current_job = this_job
end

return M
