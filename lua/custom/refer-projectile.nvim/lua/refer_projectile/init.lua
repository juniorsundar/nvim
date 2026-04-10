local M = {}

local tmux = require "refer_projectile.tmux"
local preview = require "refer_projectile.preview"

function M._scripts_dir()
    local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
    return plugin_root .. "/scripts"
end

function M.pick_project()
    local sessions = tmux.list_sessions()
    if not sessions or #sessions == 0 then
        vim.notify("refer-projectile: no tmux sessions found", vim.log.levels.INFO)
        return
    end

    -- Track the preview tab so we can close it when done
    local preview_tabpage = nil

    local function refresh_preview(session_name)
        local tabpage, win = preview.open_preview_tab()
        preview_tabpage = tabpage
        tmux.capture_pane(session_name, function(out)
            vim.schedule(function()
                preview.render_tab(tabpage, win, out)
            end)
        end)
    end

    -- Kick off preview for the first item immediately
    refresh_preview(sessions[1])

    require("refer").pick(sessions, function(selection)
        -- Close the preview tab, then switch tmux session
        preview.close_tab()
        tmux.switch_session(selection)
    end, {
        prompt = "Switch session: ",
        preview = { enabled = false },
        on_close = function()
            preview.close_tab()
        end,
        keymaps = {
            -- select_entry picks the highlighted item; select_input (default) picks
            -- the raw typed query which is empty when the user just navigates
            ["<CR>"] = function(_, builtin)
                builtin.actions.select_entry()
            end,
            ["<C-n>"] = function(_, builtin)
                builtin.actions.next_item()
                local idx = builtin.picker.selected_index
                local match = builtin.picker.current_matches[idx]
                if match then
                    refresh_preview(match.text)
                end
            end,
            ["<C-p>"] = function(_, builtin)
                builtin.actions.prev_item()
                local idx = builtin.picker.selected_index
                local match = builtin.picker.current_matches[idx]
                if match then
                    refresh_preview(match.text)
                end
            end,
            ["<Down>"] = function(_, builtin)
                builtin.actions.next_item()
                local idx = builtin.picker.selected_index
                local match = builtin.picker.current_matches[idx]
                if match then
                    refresh_preview(match.text)
                end
            end,
            ["<Up>"] = function(_, builtin)
                builtin.actions.prev_item()
                local idx = builtin.picker.selected_index
                local match = builtin.picker.current_matches[idx]
                if match then
                    refresh_preview(match.text)
                end
            end,
        },
    })
end

function M.open_project()
    vim.ui.input({ prompt = "Project path: ", default = vim.fn.expand "~" }, function(path)
        if not path or path == "" then
            return
        end

        path = vim.fn.expand(path)
        local nv_path = M._scripts_dir() .. "/nv"

        vim.system({ nv_path }, { cwd = path }, function(res)
            if res.code ~= 0 then
                vim.schedule(function()
                    vim.notify("refer-projectile: failed to open project: " .. (res.stderr or ""), vim.log.levels.ERROR)
                end)
            end
        end)
    end)
end

function M.export_scripts(dest_dir)
    dest_dir = dest_dir or vim.fn.expand "~/.local/bin"
    local scripts_dir = M._scripts_dir()

    local handle = vim.uv.fs_scandir(scripts_dir)
    while handle do
        local name, ftype = vim.uv.fs_scandir_next(handle)
        if not name then
            break
        end
        if ftype == "file" then
            local src = scripts_dir .. "/" .. name
            local dst = dest_dir .. "/" .. name
            vim.uv.fs_copyfile(src, dst, function(err)
                if err then
                    vim.schedule(function()
                        vim.notify("refer-projectile: failed to copy " .. name .. ": " .. err, vim.log.levels.ERROR)
                    end)
                else
                    vim.system({ "chmod", "+x", dst }, nil, function(res)
                        if res.code == 0 then
                            vim.schedule(function()
                                vim.notify(
                                    "refer-projectile: exported " .. name .. " to " .. dest_dir,
                                    vim.log.levels.INFO
                                )
                            end)
                        end
                    end)
                end
            end)
        end
    end
end

return M
