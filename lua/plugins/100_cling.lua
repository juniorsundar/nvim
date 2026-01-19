local compile = require "cling"

local function strip_ansi(str)
    return str:gsub("\27%[[0-9;]*m", "")
end

local function get_file_from_line(line)
    local clean = strip_ansi(line)
    local file = clean:match "^Modified regular file (.*):$"
    if file then
        return file, "Modified"
    end
    file = clean:match "^Added regular file (.*):$"
    if file then
        return file, "Added"
    end
    file = clean:match "^Removed regular file (.*):$"
    if file then
        return file, "Removed"
    end
    file = clean:match "^Renamed .* to (.*):$"
    if file then
        return file, "Renamed"
    end
    local _, b = clean:match "^diff %-%-git a/(.*) b/(.*)"
    if b then
        return b, "Git Diff"
    end
    return nil
end

local function populate_quickfix(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local qf_list = {}
    local current_file = nil
    local current_type = nil
    local last_was_gap = true

    for _, raw_line in ipairs(lines) do
        local line = strip_ansi(raw_line)
        local file, type = get_file_from_line(line)

        if file then
            current_file = vim.trim(file)
            current_type = type
            last_was_gap = true
        elseif line:match "^%s*%.%.%.%s*$" then
            last_was_gap = true
        elseif current_file then
            local old, new = line:match "^%s*([0-9]*)%s+([0-9]*):"
            if old or new then
                if last_was_gap then
                    local lnum = tonumber(new) or tonumber(old) or 1
                    local text = line:sub((line:find ":" or 0) + 1)
                    table.insert(qf_list, {
                        filename = current_file,
                        lnum = lnum,
                        text = string.format("[%s] %s", current_type or "Change", vim.trim(text)),
                    })
                    last_was_gap = false
                end
            end
        end
    end

    if #qf_list > 0 then
        vim.fn.setqflist(qf_list, "r")
        vim.notify("Quickfix populated with " .. #qf_list .. " entries", vim.log.levels.INFO)
        vim.cmd "copen"
    else
        vim.notify("No file headers or hunks found", vim.log.levels.WARN)
    end
end

compile.setup {
    wrappers = {
        {
            binary = "docker",
            command = "Docker",
            completion_cmd = "docker completion bash",
        },
        {
            binary = "nh",
            command = "NH",
            completion_cmd = "nh completions bash",
        },
        {
            binary = "uv",
            command = "UV",
            completion_cmd = "uv generate-shell-completion bash",
        },
        {
            binary = "jj",
            command = "JJ",
            completion_cmd = "jj util completion bash",
            keymaps = function(buf)
                vim.keymap.set("n", "<C-q>", function()
                    populate_quickfix(buf)
                end, { buffer = buf, silent = true, desc = "JJ: Populate Quickfix" })
            end,
        },
    },
}

vim.keymap.set("n", "<C-c><C-c>", "<cmd>Cling<cr>", { desc = "Cling" })
