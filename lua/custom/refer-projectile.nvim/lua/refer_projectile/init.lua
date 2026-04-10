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

    local current = tmux.get_current_session()
    if current then
        for i = #sessions, 1, -1 do
            if sessions[i] == current then
                table.remove(sessions, i)
                break
            end
        end
    end

    if #sessions == 0 then
        vim.notify("refer-projectile: no other tmux sessions to switch to", vim.log.levels.INFO)
        return
    end

    local function refresh_preview(session_name)
        local tabpage, win = preview.open_preview_tab()
        tmux.capture_pane(session_name, function(out)
            vim.schedule(function()
                preview.render_tab(tabpage, win, out)
            end)
        end)
    end

    refresh_preview(sessions[1])

    require("refer").pick(sessions, function(selection)
        preview.close_tab()
        tmux.switch_session(selection)
    end, {
        prompt = "Switch session: ",
        preview = { enabled = false },
        on_close = function()
            preview.close_tab()
        end,
        keymaps = {
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

local function filesystem_picker(on_confirm)
    local home = vim.fn.fnamemodify(vim.fn.expand "~", ":p"):gsub("/+$", "")
    local current_base = home

    local function normalize_dir(path)
        if not path or path == "" then
            return ""
        end
        return vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("/+$", "")
    end

    local function join_path(base, name)
        local clean_name = (name or ""):gsub("^/+", ""):gsub("/+$", "")
        if clean_name:find "^/" then
            return normalize_dir(clean_name)
        end
        local clean_base = normalize_dir(base)
        if clean_base == "" then
            return clean_name
        end
        if clean_name == "" then
            return clean_base
        end
        return clean_base .. "/" .. clean_name
    end

    local function parse_input(input)
        input = input or ""
        if input == "" then
            return home, ""
        end

        local ends_with_slash = input:sub(-1) == "/"
        local expanded = vim.fn.expand(input)

        if ends_with_slash then
            return normalize_dir(expanded), ""
        end

        local base, partial = expanded:match "^(.*)/([^/]*)$"
        if base then
            return normalize_dir(base), partial or ""
        end

        return home, expanded
    end

    local function list_dirs(base, partial)
        local dir = normalize_dir(base)
        if dir == "" or vim.fn.isdirectory(dir) ~= 1 then
            return {}
        end

        partial = partial or ""
        local partial_lower = partial:lower()
        local items = {}
        local handle = vim.uv.fs_scandir(dir)
        while handle do
            local name, ftype = vim.uv.fs_scandir_next(handle)
            if not name then
                break
            end
            if ftype == "directory" and name ~= "." and name ~= ".." then
                if partial_lower == "" or name:sub(1, #partial_lower):lower() == partial_lower then
                    table.insert(items, name .. "/")
                end
            end
        end

        table.sort(items, function(a, b)
            return a:lower() < b:lower()
        end)

        return items
    end

    local function get_highlighted_dir(builtin)
        local item = builtin.picker.current_matches[builtin.picker.selected_index]
        if not item then
            return nil
        end
        local selection = type(item) == "table" and item.text or item
        return join_path(current_base, selection)
    end

    require("refer").pick({}, function(selection)
        local dir = join_path(current_base, selection)
        if dir and vim.fn.isdirectory(dir) == 1 then
            on_confirm(dir)
        end
    end, {
        prompt = "Open project: ",
        preview = { enabled = false },
        default_text = home .. "/",
        on_change = function(query, cb)
            local base, partial = parse_input(query)
            current_base = base
            cb(list_dirs(base, partial))
        end,
        keymaps = {
            ["<CR>"] = function(_, builtin)
                builtin.actions.select_entry()
            end,
            ["<Tab>"] = function(_, builtin)
                local dir = get_highlighted_dir(builtin)
                if not dir or vim.fn.isdirectory(dir) ~= 1 then
                    builtin.picker:set_items {}
                    return
                end
                current_base = normalize_dir(dir)
                builtin.picker.ui:update_input { current_base .. "/" }
                builtin.picker:refresh(true)
            end,
            ["<C-c>"] = function(_, builtin)
                builtin.actions.close()
            end,
            ["<Esc>"] = function(_, builtin)
                builtin.actions.close()
            end,
            ["<C-n>"] = function(_, builtin)
                builtin.actions.next_item()
            end,
            ["<C-p>"] = function(_, builtin)
                builtin.actions.prev_item()
            end,
            ["<Down>"] = function(_, builtin)
                builtin.actions.next_item()
            end,
            ["<Up>"] = function(_, builtin)
                builtin.actions.prev_item()
            end,
        },
    })
end

function M.open_project()
    filesystem_picker(function(path)
        if not path or path == "" then
            return
        end

        path = vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("/+$", "")
        local session_name = " " .. path:gsub("%.", "_")

        local sessions = tmux.list_sessions()
        local exists = false
        for _, s in ipairs(sessions) do
            if s == session_name then
                exists = true
                break
            end
        end

        if not exists then
            local cmd = "cd " .. vim.fn.shellescape(path) .. " && nv ."
            local ok = tmux.create_session(session_name, cmd)
            if not ok then
                vim.notify("refer-projectile: failed to create tmux session " .. session_name, vim.log.levels.ERROR)
                return
            end
        end

        tmux.switch_session(session_name)
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
