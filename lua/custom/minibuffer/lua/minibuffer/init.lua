local fuzzy = require "minibuffer.fuzzy"
local UI = require "minibuffer.ui"
local util = require "minibuffer.util"
local api = vim.api

local active_ui = nil

local function is_binary(path)
    local f = io.open(path, "rb")
    if not f then
        return false
    end
    local chunk = f:read(1024)
    f:close()
    return chunk and chunk:find "\0"
end

local function close_existing()
    if active_ui then
        active_ui:close()
        active_ui = nil
    end

    for _, win in ipairs(api.nvim_list_wins()) do
        if api.nvim_win_is_valid(win) then
            local buf = api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            if ft == "minibuffer_input" or ft == "minibuffer_results" then
                api.nvim_win_close(win, true)
            end
        end
    end
end

local M = {}

local function complete_line(input, selection)
    if vim.startswith(selection, input) then
        return selection
    end

    local prefix = input:match("^(.*[%s%.%/:\\])" or "") or ""
    return prefix .. selection
end

function M.pick(items_or_provider, on_select, opts)
    local original_win = api.nvim_get_current_win()
    local original_buf = api.nvim_win_get_buf(original_win)
    local original_cursor = api.nvim_win_get_cursor(original_win)

    close_existing()

    opts = opts or {}
    on_select = on_select or opts.on_select

    local available_sorters = opts.available_sorters or { "blink", "native", "lua", "mini" }
    local sorter_idx = 1
    local prompt_text = opts.prompt or "> "
    local custom_sorter = opts.sorter

    local parser = opts.parser
    if not parser and opts.selection_format then
        parser = function(s)
            return util.parse_selection(s, opts.selection_format)
        end
    end

    local use_blink = fuzzy.has_blink() and type(items_or_provider) == "table" and not custom_sorter

    if use_blink then
        fuzzy.register_items(items_or_provider)
    end

    local ui = UI.new(prompt_text)
    active_ui = ui
    local input_buf, _ = ui:create_windows()

    local current_matches = {}
    local marked = {}
    local selected_index = 1
    local is_previewing = false

    local function preview()
        if #current_matches == 0 then
            return
        end
        local selection = current_matches[selected_index]
        if not selection then
            return
        end

        local data = parser and parser(selection)
        if data and data.filename and api.nvim_win_is_valid(original_win) then
            local filename = data.filename
            local lnum = data.lnum or 1
            local col = data.col or 1

            is_previewing = true
            api.nvim_win_call(original_win, function()
                local bufnr = vim.fn.bufnr(filename)
                if bufnr ~= -1 and api.nvim_buf_is_loaded(bufnr) then
                    if api.nvim_win_get_buf(original_win) ~= bufnr then
                        api.nvim_win_set_buf(original_win, bufnr)
                    end
                else
                    local buf = api.nvim_create_buf(false, true)
                    vim.bo[buf].bufhidden = "wipe"
                    vim.bo[buf].buftype = "nofile"
                    vim.bo[buf].swapfile = false

                    local existing = vim.fn.bufnr(filename)
                    if existing == -1 then
                        pcall(api.nvim_buf_set_name, buf, filename)
                    else
                        pcall(api.nvim_buf_set_name, buf, filename .. " (Preview)")
                    end

                    if is_binary(filename) then
                        api.nvim_buf_set_lines(buf, 0, -1, false, { "[Binary File - Preview Disabled]" })
                    else
                        local lines = {}
                        if vim.fn.filereadable(filename) == 1 then
                            lines = vim.fn.readfile(filename, "", 1000)
                        end

                        for i, line in ipairs(lines) do
                            if line:find "[\r\n]" then
                                lines[i] = line:gsub("[\r\n]", " ")
                            end
                        end

                        api.nvim_buf_set_lines(buf, 0, -1, false, lines)

                        local ft = vim.filetype.match { filename = filename }
                        if ft then
                            vim.bo[buf].filetype = ft
                        end
                    end

                    api.nvim_win_set_buf(original_win, buf)
                end

                if lnum and col then
                    pcall(api.nvim_win_set_cursor, original_win, { lnum, col - 1 })
                    vim.cmd "normal! zz"
                end
            end)
            is_previewing = false
        end
    end

    local function refresh()
        local input = api.nvim_get_current_line()

        if opts.on_change then
            selected_index = 1
            opts.on_change(input, function(matches)
                current_matches = matches or {}

                if selected_index > #current_matches then
                    selected_index = #current_matches
                end
                if selected_index < 1 and #current_matches > 0 then
                    selected_index = 1
                end

                ui:render(current_matches, selected_index, marked)
                preview()
            end)
            return
        end

        current_matches = fuzzy.filter(items_or_provider, input, {
            sorter = custom_sorter,
            use_blink = use_blink,
        })

        selected_index = 1
        ui:render(current_matches, selected_index, marked)
        preview()
    end

    -- Actions
    local actions = {}

    actions.refresh = refresh

    function actions.next_item()
        if #current_matches > 0 then
            selected_index = (selected_index % #current_matches) + 1
            ui:render(current_matches, selected_index, marked)
            preview()
        end
    end

    function actions.prev_item()
        if #current_matches > 0 then
            selected_index = ((selected_index - 2) % #current_matches) + 1
            ui:render(current_matches, selected_index, marked)
            preview()
        end
    end

    function actions.complete_selection()
        local selection = current_matches[selected_index]
        local input = api.nvim_get_current_line()

        if selection then
            local new_line = complete_line(input, selection)
            ui:update_input { new_line }
            refresh()
        end
    end

    function actions.toggle_mark()
        local selection = current_matches[selected_index]
        if selection then
            marked[selection] = not marked[selection]
            ui:render(current_matches, selected_index, marked)
        end
        actions.next_item()
    end

    function actions.select_input()
        local current_input = api.nvim_get_current_line()
        ui:close()
        if active_ui == ui then
            active_ui = nil
        end

        if on_select and current_input ~= "" then
            -- For input selection, we don't typically have a parser for free text
            on_select(current_input, nil)
        end
    end

    function actions.select_entry()
        local selection = current_matches[selected_index]
        if selection then
            ui:close()
            if active_ui == ui then
                active_ui = nil
            end

            local data = parser and parser(selection)
            on_select(selection, data)
        end
    end

    function actions.send_to_grep()
        local lines = {}
        for item, is_marked in pairs(marked) do
            if is_marked then
                table.insert(lines, item)
            end
        end

        if #lines == 0 then
            local selection = current_matches[selected_index]
            if selection then
                table.insert(lines, selection)
            end
        end

        if #lines > 0 then
            ui:close()
            if active_ui == ui then
                active_ui = nil
            end

            local ok, grep_buf = pcall(require, "buffers.grep")
            if ok then
                grep_buf.create_buffer(lines)
            else
                vim.notify("buffers.grep module not found", vim.log.levels.WARN)
            end
        end
    end

    function actions.close()
        if api.nvim_win_is_valid(original_win) and api.nvim_buf_is_valid(original_buf) then
            api.nvim_win_set_buf(original_win, original_buf)
            api.nvim_win_set_cursor(original_win, original_cursor)
        end

        ui:close()
        if active_ui == ui then
            active_ui = nil
        end
    end

    function actions.cycle_sorter()
        sorter_idx = (sorter_idx % #available_sorters) + 1
        local name = available_sorters[sorter_idx]

        opts.sorter = fuzzy.sorters[name]

        vim.notify("Sorter switched to: " .. name, vim.log.levels.INFO)

        refresh()
    end

    local parameters = {
        original_win = original_win,
        original_buf = original_buf,
        original_cursor = original_cursor,
    }

    -- Mappings
    local default_keymaps = {
        ["<Tab>"] = "complete_selection",
        ["<C-n>"] = "next_item",
        ["<C-p>"] = "prev_item",
        ["<Down>"] = "next_item",
        ["<Up>"] = "prev_item",
        ["<CR>"] = "select_input",
        ["<Esc>"] = "close",
        ["<C-c>"] = "close",
        ["<C-g>"] = "send_to_grep",
        ["<C-s>"] = "cycle_sorter",
    }

    local keymaps = vim.tbl_extend("force", default_keymaps, opts.keymaps or {})

    local function map(key, func)
        vim.keymap.set("i", key, func, { buffer = input_buf })
    end

    for key, handler in pairs(keymaps) do
        if type(handler) == "string" then
            if actions[handler] then
                map(key, actions[handler])
            end
        elseif type(handler) == "function" then
            map(key, function()
                local selection = current_matches[selected_index]
                if selection then
                    local builtin = {
                        actions = actions,
                        parameters = parameters,
                        marked = marked,
                    }
                    handler(selection, builtin)
                end
            end)
        end
    end

    -- Autocmds
    local group = api.nvim_create_augroup("MinibufferLive", { clear = true })
    api.nvim_create_autocmd("TextChangedI", {
        buffer = input_buf,
        group = group,
        callback = refresh,
    })

    api.nvim_create_autocmd("WinLeave", {
        buffer = input_buf,
        group = group,
        callback = function()
            if is_previewing then
                return
            end

            -- Restore original view if valid
            if api.nvim_win_is_valid(original_win) and api.nvim_buf_is_valid(original_buf) then
                api.nvim_win_set_buf(original_win, original_buf)
                api.nvim_win_set_cursor(original_win, original_cursor)
            end

            ui:close()
            if active_ui == ui then
                active_ui = nil
            end
        end,
    })

    refresh()
    vim.cmd "startinsert"
end

return M
