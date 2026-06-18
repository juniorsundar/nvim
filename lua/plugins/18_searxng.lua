local SEARCH_URL = "http://localhost:5340/search"
local MAX_SEARCH_RESULTS = 10

local function ensure_markdown_conceal(buf)
    if vim.b[buf].web_search_markdown_conceal then
        return
    end

    vim.api.nvim_buf_call(buf, function()
        vim.cmd [[
            syntax match WebSearchMarkdownLinkOpen /\[/ conceal
            syntax match WebSearchMarkdownLinkMiddle /\](/ conceal
            syntax match WebSearchMarkdownLinkClose /)/ conceal
            syntax match WebSearchMarkdownLinkUrl /\](\zs[^)]\+\ze)/ conceal
        ]]
    end)

    vim.b[buf].web_search_markdown_conceal = true
end

local function markdown_link_text(text)
    return tostring(text or "Untitled"):gsub("%[", "\\["):gsub("%]", "\\]")
end

local function compact_text(text)
    return vim.trim(tostring(text or ""):gsub("%s+", " "))
end

local function format_search_results(query, payload)
    local lines = {
        "# Web Search: " .. query,
        "",
    }

    if payload.answer and payload.answer ~= "" then
        table.insert(lines, "## Answer")
        table.insert(lines, "")
        table.insert(lines, compact_text(payload.answer))
        table.insert(lines, "")
    end

    local results = payload.results or {}
    if #results == 0 then
        table.insert(lines, "No results found.")
        return lines
    end

    table.insert(lines, "## Results")
    table.insert(lines, "")

    for index, item in ipairs(results) do
        if index > MAX_SEARCH_RESULTS then
            break
        end

        local title = markdown_link_text(item.title)
        local url = tostring(item.url or "")
        local snippet = compact_text(item.content or item.snippet or "")

        if url ~= "" then
            table.insert(lines, string.format("%d. [%s](%s)", index, title, url))
        else
            table.insert(lines, string.format("%d. %s", index, title))
        end

        if snippet ~= "" then
            table.insert(lines, "   " .. snippet)
        end

        table.insert(lines, "")
    end

    if payload.suggestions and #payload.suggestions > 0 then
        table.insert(lines, "## Suggestions")
        table.insert(lines, "")
        for _, suggestion in ipairs(payload.suggestions) do
            table.insert(lines, "- " .. compact_text(suggestion))
        end
        table.insert(lines, "")
    end

    return lines
end

local function render_markdown_buffer(buf, title, lines)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    vim.bo[buf].modifiable = true
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = ""
    vim.bo[buf].syntax = "markdown"

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_set_name(buf, title)
    ensure_markdown_conceal(buf)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true, desc = "Close search results" })
end

local function open_results_window(smods)
    if smods and smods.tab and smods.tab >= 0 then
        vim.cmd "tabnew"
    else
        local prefix = "botright"
        if smods and smods.split == "topleft" then
            prefix = "topleft"
        elseif smods and smods.split == "botright" then
            prefix = "botright"
        end

        if smods and smods.vertical then
            vim.cmd(prefix .. " vsplit")
        else
            vim.cmd(prefix .. " split")
        end
    end

    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, buf)
    vim.wo[win].wrap = true
    vim.wo[win].conceallevel = 2
    vim.wo[win].concealcursor = "nc"
    return win, buf
end

local function close_results_window(win)
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
end

local function web_search(opts)
    local win, buf = open_results_window(opts and opts.smods)
    render_markdown_buffer(buf, "[Web Search]", {
        "# Web Search",
        "",
        "Waiting for query...",
    })

    vim.ui.input({ prompt = "Web Search: " }, function(query)
        query = query and vim.trim(query) or ""
        if query == "" then
            close_results_window(win)
            return
        end

        render_markdown_buffer(buf, "[Web Search]", {
            "# Web Search: " .. query,
            "",
            "Searching...",
        })

        require("micro.http").request({
            url = SEARCH_URL,
            query = {
                q = query,
                format = "json",
            },
            headers = {
                Accept = "application/json",
            },
        }, function(err, res)
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end

            if err then
                render_markdown_buffer(buf, "[Web Search]", {
                    "# Web Search: " .. query,
                    "",
                    "Search failed:",
                    "",
                    "```text",
                    err.message,
                    "```",
                })
                return
            end

            if res.status >= 400 then
                render_markdown_buffer(buf, "[Web Search]", {
                    "# Web Search: " .. query,
                    "",
                    "Search failed with HTTP " .. res.status .. ".",
                })
                return
            end

            if not res.json then
                render_markdown_buffer(buf, "[Web Search]", {
                    "# Web Search: " .. query,
                    "",
                    "SearXNG returned a non-JSON response.",
                    "",
                    "```",
                    res.body or "",
                    "```",
                })
                return
            end

            render_markdown_buffer(buf, "[Web Search]", format_search_results(query, res.json))
        end)
    end)
end

vim.api.nvim_create_user_command("WebSearch", function(opts)
    web_search(opts)
end, { bar = true, nargs = 0 })

vim.keymap.set("n", "<leader>s", "<cmd>WebSearch<cr>", { desc = "Web Search" })
