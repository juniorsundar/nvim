local M = {}
local api = vim.api

local function simple_fuzzy_score(str, pattern)
    if pattern == "" then
        return 0
    end
    local total_score = 0
    local run = 0
    local str_idx = 1
    local pat_idx = 1
    local str_len = #str
    local pat_len = #pattern
    local str_lower = str:lower()
    local pat_lower = pattern:lower()

    while pat_idx <= pat_len and str_idx <= str_len do
        local pat_char = pat_lower:sub(pat_idx, pat_idx)
        local found_idx = string.find(str_lower, pat_char, str_idx, true)

        if not found_idx then
            return nil
        end -- Character not found in order

        -- Scoring:
        -- 1. Distance penalty (farther apart = lower score)
        local distance = found_idx - str_idx
        local score = 100 - distance

        -- 2. Consecutive match bonus
        if distance == 0 then
            run = run + 10
            score = score + run
        else
            run = 0
        end

        -- 3. Start of word bonus (e.g. match 'b' in 'foo_bar')
        if found_idx == 1 or str:sub(found_idx - 1, found_idx - 1):match "[^%w]" then
            score = score + 20
        end

        -- 4. CamelCase bonus (e.g. match 'B' in 'fooBar')
        if found_idx > 1 and str:sub(found_idx, found_idx):match "%u" then
            score = score + 20
        end

        total_score = total_score + score
        str_idx = found_idx + 1
        pat_idx = pat_idx + 1
    end

    if pat_idx <= pat_len then
        return nil
    end
    return total_score
end

local function complete_line(input, selection)
    if vim.startswith(selection, input) then
        return selection
    end

    local prefix = input:match "^(.*[%s%.%/:\\])" or ""
    return prefix .. selection
end

function M.pick(items_or_provider, on_select, opts)
    opts = opts or {}
    local prompt_text = opts.prompt or "> "
    local custom_sorter = opts.sorter

    local ns_id = api.nvim_create_namespace "minibuffer"

    local input_buf = api.nvim_create_buf(false, true)
    local results_buf = api.nvim_create_buf(false, true)

    vim.bo[input_buf].filetype = "minibuffer_input"
    vim.bo[results_buf].filetype = "minibuffer_results"

    vim.cmd "botright 10new"
    local results_win = api.nvim_get_current_win()
    api.nvim_win_set_buf(results_win, results_buf)

    -- Configure Results Window
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.cursorline = false
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.spell = false
    vim.opt_local.list = false

    vim.cmd "leftabove 1new"
    local input_win = api.nvim_get_current_win()
    api.nvim_win_set_buf(input_win, input_buf)

    -- Configure Input Window
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.spell = false
    vim.opt_local.list = false
    vim.cmd "resize 1"

    local prompt_ns = api.nvim_create_namespace "minibuffer_prompt"
    api.nvim_buf_set_extmark(input_buf, prompt_ns, 0, 0, {
        virt_text = { { prompt_text, "Title" } },
        virt_text_pos = "inline",
        right_gravity = false,
    })

    local current_matches = {}
    local selected_index = 1

    local function render()
        if #current_matches == 0 then
            api.nvim_buf_set_lines(results_buf, 0, -1, false, { " " })
            return
        end

        api.nvim_buf_set_lines(results_buf, 0, -1, false, current_matches)

        api.nvim_buf_clear_namespace(results_buf, ns_id, 0, -1)

        if selected_index > 0 and selected_index <= #current_matches then
            local selected_text = current_matches[selected_index]

            api.nvim_buf_set_extmark(results_buf, ns_id, selected_index - 1, 0, {
                end_row = selected_index - 1,
                end_col = #selected_text,
                hl_group = "Visual",
                priority = 100,
            })
            api.nvim_win_set_cursor(results_win, { selected_index, 0 })
        end
    end

    local function close()
        if api.nvim_win_is_valid(results_win) then
            api.nvim_win_close(results_win, true)
        end
        if api.nvim_win_is_valid(input_win) then
            api.nvim_win_close(input_win, true)
        end
        vim.cmd "stopinsert"
    end

    local function on_change()
        local input = api.nvim_get_current_line()

        -- DYNAMIC PROVIDER (Function)
        if type(items_or_provider) == "function" then
            current_matches = items_or_provider(input)

        -- STATIC LIST (Table) -> Apply Fuzzy Sort
        else
            if input == "" then
                current_matches = items_or_provider
            else
                if custom_sorter then
                    current_matches = custom_sorter(items_or_provider, input)
                else
                    local scored = {}
                    for _, item in ipairs(items_or_provider) do
                        local score = simple_fuzzy_score(item, input)
                        if score then
                            table.insert(scored, { item = item, score = score })
                        end
                    end
                    table.sort(scored, function(a, b)
                        return a.score > b.score
                    end)
                    current_matches = {}
                    for _, entry in ipairs(scored) do
                        table.insert(current_matches, entry.item)
                    end
                end
            end
        end

        selected_index = 1
        render()
    end

    local function map(key, func)
        vim.keymap.set("i", key, func, { buffer = input_buf })
    end

    map("<Tab>", function()
        local selection = current_matches[selected_index]
        local input = api.nvim_get_current_line()

        if selection then
            local new_line = complete_line(input, selection)

            api.nvim_buf_set_lines(input_buf, 0, -1, false, { new_line })
            api.nvim_win_set_cursor(input_win, { 1, #new_line })
            on_change()
        end
    end)

    -- Navigation: Down
    map("<C-n>", function()
        if selected_index < #current_matches then
            selected_index = selected_index + 1
            render()
        end
    end)

    -- Navigation: Up
    map("<C-p>", function()
        if selected_index > 1 then
            selected_index = selected_index - 1
            render()
        end
    end)

    -- Confirm Selection
    map("<CR>", function()
        local current_input = api.nvim_get_current_line()
        close()

        if on_select and current_input ~= "" then
            on_select(current_input)
        end
    end)

    -- Close
    map("<Esc>", close)
    map("<C-c>", close)

    -- Initial setup
    local group = api.nvim_create_augroup("MinibufferLive", { clear = true })
    api.nvim_create_autocmd("TextChangedI", {
        buffer = input_buf,
        group = group,
        callback = on_change,
    })

    on_change()
    vim.cmd "startinsert"
end

vim.keymap.set("n", "<A-x>", function()
    local all_commands = vim.fn.getcompletion("", "command")

    M.pick(all_commands, function(input_text)
        vim.cmd(input_text)
    end, { prompt = "M-x > " })
end, { desc = "Minibuffer Command Palette" })

local function fetch_references(on_result)
    local clients = vim.lsp.get_clients { bufnr = 0 }
    local client = clients[1]

    if not client then
        print "No LSP client attached"
        return
    end

    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    params.context = { includeDeclaration = true }

    vim.lsp.buf_request(0, "textDocument/references", params, function(err, result, _, _)
        if err then
            print("LSP Error: " .. tostring(err))
            return
        end
        if not result or vim.tbl_isempty(result) then
            print "No references found"
            return
        end

        local items = {}

        for _, loc in ipairs(result) do
            local filename = vim.uri_to_fname(loc.uri)
            local lnum = loc.range.start.line + 1
            local col = loc.range.start.character + 1

            local relative_path = vim.fn.fnamemodify(filename, ":.")
            local entry = string.format("%s:%d:%d", relative_path, lnum, col)
            table.insert(items, entry)
        end

        on_result(items)
    end)
end

vim.keymap.set("n", "<C-x>t", function()
    fetch_references(function(items)
        M.pick(items, function(selection)
            if not selection or selection == "" then
                return
            end

            local filename, lnum, col = selection:match "^(.*):(%d+):(%d+)$"

            if filename and lnum and col then
                vim.cmd("edit " .. filename)
                vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
            end
        end)
    end)
end, { desc = "LSP References via Minibuffer" })

return M
