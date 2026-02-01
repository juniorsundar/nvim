local fuzzy = require "minibuffer.fuzzy"
local UI = require "minibuffer.ui"
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
    close_existing()

    opts = opts or {}
    local prompt_text = opts.prompt or "> "
    local custom_sorter = opts.sorter

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

    local function refresh()
        local input = api.nvim_get_current_line()

        current_matches = fuzzy.filter(items_or_provider, input, {
            sorter = custom_sorter,
            use_blink = use_blink,
        })

        selected_index = 1
        ui:render(current_matches, selected_index, marked)
    end

    -- Actions
    local actions = {}

    function actions.next_item()
        if #current_matches > 0 then
            selected_index = (selected_index % #current_matches) + 1
            ui:render(current_matches, selected_index, marked)
        end
    end

    function actions.prev_item()
        if #current_matches > 0 then
            selected_index = ((selected_index - 2) % #current_matches) + 1
            ui:render(current_matches, selected_index, marked)
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
            on_select(current_input)
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
        ui:close()
        if active_ui == ui then
            active_ui = nil
        end
    end

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

    for key, action in pairs(keymaps) do
        if type(action) == "string" then
            if actions[action] then
                map(key, actions[action])
            end
        elseif type(action) == "function" then
            map(key, action)
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
