local panel = require "micro.panel"

local M = {}

local defaults = {
    enabled = false,
    auto_hover = {
        enabled = false,
        delay = 500,
    },
    layout = "eldoc",
    reduce_split_jank = true,
    opts = {
        border = "rounded",
        relative = "editor",
        offset_x = vim.o.columns,
        ratio = 0.4,
        max_height = 15,
    },
}

local config = defaults

local function with_splitkeep_screen(fn)
    if not config.reduce_split_jank then
        fn()
        return
    end
    local prev = vim.o.splitkeep
    pcall(function()
        vim.o.splitkeep = "screen"
    end)
    local ok, err = pcall(fn)
    pcall(function()
        vim.o.splitkeep = prev
    end)
    if not ok then
        error(err)
    end
end

local function close_eldoc_window()
    with_splitkeep_screen(function()
        panel.close "eldoc"
    end)
end

local function extract_links_to_footnotes(lines)
    local processed_lines = {}
    local footnotes = {}
    local link_count = 0
    local in_code_block = false

    for _, line in ipairs(lines) do
        if line:match "^%s*```" then
            in_code_block = not in_code_block
        end

        local processed_line = line

        if not in_code_block then
            processed_line = line:gsub("%[([^%]]+)%]%(([^%)]+)%)", function(text, url)
                link_count = link_count + 1
                table.insert(footnotes, string.format("[^%d]: %s", link_count, url))
                return string.format("%s[^%d]", text, link_count)
            end)
        end

        table.insert(processed_lines, processed_line)
    end

    if #footnotes > 0 then
        table.insert(processed_lines, "")
        for _, footnote in ipairs(footnotes) do
            table.insert(processed_lines, footnote)
        end
    end

    return processed_lines
end

local function eldoc()
    -- Returns true once a reply has been shown, so later clients' replies are ignored.
    local handler = function(err, result)
        if err or not result or not result.contents then
            return
        end

        local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)

        if vim.tbl_isempty(lines) then
            return
        end

        if config.layout == "eldoc" then
            if panel.get "eldoc" then
                return
            end

            lines = extract_links_to_footnotes(lines)

            local padded_lines = vim.list_extend({ "" }, lines)
            table.insert(padded_lines, "")

            local max_height = math.floor(vim.o.lines * config.opts.ratio)
            if config.opts.max_height then
                max_height = math.min(max_height, config.opts.max_height)
            end

            local eldoc_win_id, eldoc_buf_id
            with_splitkeep_screen(function()
                eldoc_win_id, eldoc_buf_id = panel.open("eldoc", padded_lines, {
                    split = "below",
                    win = -1,
                    height = math.min(max_height, #padded_lines),
                    style = "minimal",
                })
            end)
            vim.api.nvim_buf_set_name(eldoc_buf_id, "[LSP Eldoc]")
            vim.api.nvim_set_option_value("filetype", "markdown", { buf = eldoc_buf_id })
            pcall(vim.treesitter.start, eldoc_buf_id, "markdown")
            vim.api.nvim_set_option_value("conceallevel", 2, { win = eldoc_win_id })
            vim.api.nvim_set_option_value("concealcursor", "nc", { win = eldoc_win_id })
            vim.api.nvim_set_option_value("wrap", true, { win = eldoc_win_id })
            vim.api.nvim_set_option_value("linebreak", true, { win = eldoc_win_id })
            vim.api.nvim_set_option_value("breakindent", true, { win = eldoc_win_id })
            vim.api.nvim_set_option_value("signcolumn", "yes:2", { win = eldoc_win_id })
            vim.api.nvim_set_option_value("winhl", "SignColumn:Normal", { win = eldoc_win_id })

            local function open_link()
                local line = vim.api.nvim_get_current_line()
                local cWORD = vim.fn.expand "<cWORD>"
                local ref = cWORD:match "%[%^(%d+)%]"
                local target

                if line:match "^%[%^%d+%]:" then
                    target = line:match "%[%^%d+%]:%s*(.+)"
                elseif ref then
                    local buf_lines = vim.api.nvim_buf_get_lines(eldoc_buf_id, 0, -1, false)
                    for _, l in ipairs(buf_lines) do
                        local match = l:match("%[%^" .. ref .. "%]:%s*(.+)")
                        if match then
                            target = match
                            break
                        end
                    end
                else
                    target = cWORD:match "(https?://[%w-_%.%?%.:/%%+=&]+)" or vim.fn.expand "<cfile>"
                end

                if not target or target == "" then
                    vim.notify("No valid link or file found under cursor", vim.log.levels.WARN)
                    return
                end

                if target:match "^https?://" then
                    vim.ui.open(target)
                else
                    local path = target
                    local l_num, c_num
                    if path:match "^file://" then
                        path = path:sub(8)
                        local file_path
                        file_path, l_num, c_num = path:match "^([^#]+)#(%d+)#(%d+)$"
                        if not file_path then
                            file_path, l_num = path:match "^([^#]+)#(%d+)$"
                        end
                        path = file_path or path
                    end
                    local expanded_path = vim.fn.expand(path)
                    if vim.fn.filereadable(expanded_path) == 1 then
                        vim.cmd "wincmd p"
                        vim.cmd("edit " .. vim.fn.fnameescape(expanded_path))
                        if l_num then
                            local l = tonumber(l_num)
                            local c = c_num and math.max(0, tonumber(c_num) - 1) or 0
                            local max_l = vim.api.nvim_buf_line_count(0)
                            l = math.min(l, max_l)
                            pcall(vim.api.nvim_win_set_cursor, 0, { l, c })
                        end
                    else
                        vim.notify("File not found: " .. target, vim.log.levels.WARN)
                    end
                end
            end

            vim.keymap.set("n", "gx", open_link, {
                buffer = eldoc_buf_id,
                silent = true,
                noremap = true,
                desc = "Open markdown link or footnote",
            })
            vim.keymap.set("n", "q", close_eldoc_window, {
                buffer = eldoc_buf_id,
                silent = true,
                noremap = true,
                desc = "Close LSP eldoc window",
            })
            return true
        elseif config.layout == "float" then
            vim.lsp.util.open_floating_preview(lines, "markdown", config.opts)
            return true
        end
    end

    require("micro.lsp").request_cursor("hover", 0, "textDocument/hover", handler)
end

function M.show()
    eldoc()
end

function M.setup(opts)
    config = vim.tbl_deep_extend("force", defaults, opts or {})

    vim.o.updatetime = config.auto_hover.delay

    local lsp_hover_augroup = vim.api.nvim_create_augroup("LspHoverOnHold", { clear = true })
    local eldoc_close_augroup = vim.api.nvim_create_augroup("LspEldocAutoClose", { clear = true })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
        group = eldoc_close_augroup,
        callback = function()
            local eldoc_win_id = panel.get "eldoc"
            if not eldoc_win_id then
                return
            end
            local current_win = vim.api.nvim_get_current_win()
            if current_win ~= eldoc_win_id then
                close_eldoc_window()
            end
        end,
        desc = "Close LSP eldoc window when cursor moves or context changes",
    })

    vim.api.nvim_create_autocmd("CursorHold", {
        group = lsp_hover_augroup,
        pattern = "*",
        callback = function()
            if not config.auto_hover.enabled then
                return
            end
            eldoc()
        end,
        desc = "Show LSP hover documentation on CursorHold (silently ignores empty responses)",
    })
end

--- Scroll the eldoc window without switching focus.
---@param direction integer Positive scrolls down; negative scrolls up.
---@param step? integer Number of lines (default 4).
function M.scroll(direction, step)
    local eldoc_win_id = panel.get "eldoc"
    if not eldoc_win_id then
        return
    end
    local lines = step or 4
    local scroll_key = direction > 0 and "\5" or "\25"
    vim.api.nvim_win_call(eldoc_win_id, function()
        vim.cmd(string.format("normal! %d%s", lines, scroll_key))
    end)
end

-- Command fargs are strings, so numeric arguments are converted here.
M.subcommands = {
    hover = {
        show = function()
            M.show()
        end,
        scroll = function(direction, step)
            M.scroll(tonumber(direction) or 1, tonumber(step))
        end,
    },
}

return M
