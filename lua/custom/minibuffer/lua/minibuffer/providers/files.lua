local M = {}
local minibuffer = require "minibuffer"
local util = require "minibuffer.util"

local current_fd_job = nil

function M.files()
    if current_fd_job then
        current_fd_job:kill()
        current_fd_job = nil
    end

    local files_list = {}
    local ignored_dirs = { ".git", ".jj", "node_modules", ".cache" }
    local cmd = { "fd", "-H", "--type", "f" }
    for _, dir in ipairs(ignored_dirs) do
        table.insert(cmd, "--exclude")
        table.insert(cmd, dir)
    end

    local picker = minibuffer.pick({}, nil, {
        prompt = "Files (Loading...) > ",
        keymaps = {
            ["<Tab>"] = "toggle_mark",
            ["<CR>"] = "select_entry",
        },
        parser = util.parsers.file,
        on_select = function(selection, data)
            util.jump_to_location(selection, data)
            pcall(vim.cmd, 'normal! g`"')
        end,
        on_close = function()
            if current_fd_job then
                current_fd_job:kill()
                current_fd_job = nil
            end
        end,
    })

    current_fd_job = vim.system(cmd, { text = true }, function(out)
        current_fd_job = nil
        if out.code ~= 0 then
            -- If killed (code 143), don't show error
            if out.code ~= 143 then
                vim.schedule(function()
                    vim.notify("fd command failed: " .. (out.stderr or ""), vim.log.levels.ERROR)
                end)
            end
            return
        end
        local lines = vim.split(out.stdout, "\n", { trimempty = true })
        vim.schedule(function()
            if picker and picker.ui then
                picker.ui:set_prompt "Files > "
                picker:set_items(lines)
            end
        end)
    end)
end

local current_job = nil
local grep_timer = nil

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
    if grep_timer then
        grep_timer:stop()
        grep_timer:close()
        grep_timer = nil
    end

    if current_job then
        current_job:kill()
        current_job = nil
    end

    if not query or #query < 2 then
        update_ui_callback {}
        return
    end

    grep_timer = vim.uv.new_timer()
    grep_timer:start(
        100,
        0,
        vim.schedule_wrap(function()
            grep_timer:close()
            grep_timer = nil

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
        end)
    )
end

return M
