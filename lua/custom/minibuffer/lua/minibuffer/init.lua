local fuzzy = require "minibuffer.fuzzy"
local UI = require "minibuffer.ui"
local util = require "minibuffer.util"
local api = vim.api

local active_ui = nil

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
    local prompt_text = opts.prompt or "> "
    local custom_sorter = opts.sorter
    local selection_format = opts.selection_format or "lsp"

    -- Determine if we can use blink
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

        local data = util.parse_selection(selection, selection_format)
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

                    local lines = {}
                    if vim.fn.filereadable(filename) == 1 then
                        lines = vim.fn.readfile(filename)
                    end
                    api.nvim_buf_set_lines(buf, 0, -1, false, lines)

                    local ft = vim.filetype.match { filename = filename }
                    if ft then
                        vim.bo[buf].filetype = ft
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
    end

    function actions.select_input()
        local current_input = api.nvim_get_current_line()
        ui:close()
        if active_ui == ui then
            active_ui = nil
        end

        if on_select and current_input ~= "" then
            on_select(current_input, selection_format)
        end
    end

    function actions.select_entry()
        local selection = current_matches[selected_index]
        if selection then
            ui:close()
            if active_ui == ui then
                active_ui = nil
            end
            on_select(selection)
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
