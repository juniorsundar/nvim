local fuzzy = require "minibuffer.fuzzy"
local UI = require "minibuffer.ui"
local api = vim.api

local M = {}

local function complete_line(input, selection)
    if vim.startswith(selection, input) then
        return selection
    end

    local prefix = input:match("^(.*[%s%.%/:\\])" or "") or ""
    return prefix .. selection
end

function M.pick(items_or_provider, on_select, opts)
    opts = opts or {}
    local prompt_text = opts.prompt or "> "
    local custom_sorter = opts.sorter

    -- Determine if we can use blink
    local use_blink = fuzzy.has_blink() and type(items_or_provider) == "table" and not custom_sorter

    if use_blink then
        fuzzy.register_items(items_or_provider)
    end

    local ui = UI.new(prompt_text)
    local input_buf, _ = ui:create_windows()

    local current_matches = {}
    local selected_index = 1

    local function refresh()
        local input = api.nvim_get_current_line()

        current_matches = fuzzy.filter(items_or_provider, input, {
            sorter = custom_sorter,
            use_blink = use_blink,
        })

        selected_index = 1
        ui:render(current_matches, selected_index)
    end

    -- Mappings
    local function map(key, func)
        vim.keymap.set("i", key, func, { buffer = input_buf })
    end

    map("<Tab>", function()
        local selection = current_matches[selected_index]
        local input = api.nvim_get_current_line()

        if selection then
            local new_line = complete_line(input, selection)
            ui:update_input { new_line }
            refresh()
        end
    end)

    map("<C-n>", function()
        if selected_index < #current_matches then
            selected_index = selected_index + 1
            ui:render(current_matches, selected_index)
        end
    end)

    map("<C-p>", function()
        if selected_index > 1 then
            selected_index = selected_index - 1
            ui:render(current_matches, selected_index)
        end
    end)

    map("<CR>", function()
        local current_input = api.nvim_get_current_line()
        ui:close()

        if on_select and current_input ~= "" then
            on_select(current_input)
        end
    end)

    map("<Esc>", function()
        ui:close()
    end)
    map("<C-c>", vim.cmd "stopinsert")

    -- Autocmds
    local group = api.nvim_create_augroup("MinibufferLive", { clear = true })
    api.nvim_create_autocmd("TextChangedI", {
        buffer = input_buf,
        group = group,
        callback = refresh,
    })

    refresh()
    vim.cmd "startinsert"
end

return M
