local SEARCH_URL = "http://localhost:5340/search"
local MAX_SEARCH_RESULTS = 10

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

local function open_markdown_window(title, lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    local width = math.min(math.floor(vim.o.columns * 0.85), 100)
    local height = math.min(math.floor(vim.o.lines * 0.75), math.max(#lines + 2, 12))
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        border = "rounded",
        title = " " .. title .. " ",
        title_pos = "center",
        width = width,
        height = height,
        row = row,
        col = col,
    })

    vim.wo[win].wrap = true
    vim.wo[win].conceallevel = 2
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true, desc = "Close search results" })
    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true, desc = "Close search results" })
end

local function web_search()
    vim.ui.input({ prompt = "Web Search: " }, function(query)
        query = query and vim.trim(query) or ""
        if query == "" then
            return
        end

        vim.notify("Searching web for: " .. query, vim.log.levels.INFO)

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
            if err then
                vim.notify(err.message, vim.log.levels.ERROR)
                return
            end

            if res.status >= 400 then
                vim.notify("Web search failed with HTTP " .. res.status, vim.log.levels.ERROR)
                return
            end

            if not res.json then
                open_markdown_window("Web Search", {
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

            open_markdown_window("Web Search", format_search_results(query, res.json))
        end)
    end)
end

vim.keymap.set("n", "<leader>s", web_search, { desc = "Web Search" })
