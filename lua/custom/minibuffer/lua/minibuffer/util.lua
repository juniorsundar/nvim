local M = {}

function M.is_binary(path)
    local f = io.open(path, "rb")
    if not f then
        return false
    end
    local chunk = f:read(1024)
    f:close()
    return chunk and chunk:find "\0"
end

function M.complete_line(input, selection)
    if vim.startswith(selection, input) then
        return selection
    end

    local prefix = input:match("^(.*[%s%.%/:\\])" or "") or ""
    return prefix .. selection
end

local schemas = {
    buffer = {
        pattern = "^(%d+):%s+(.-):(%d+):(%d+)",
        keys = { "bufnr", "filename", "lnum", "col" },
        types = { bufnr = tonumber, lnum = tonumber, col = tonumber },
    },
    lsp = {
        pattern = "^(.-):(%d+):(%d+)",
        keys = { "filename", "lnum", "col" },
        types = { lnum = tonumber, col = tonumber },
    },
    grep = {
        pattern = "^(.-):(%d+):(%d+):(.*)",
        keys = { "filename", "lnum", "col", "content" },
        types = { lnum = tonumber, col = tonumber },
    },
    file = {
        pattern = "^(.*)",
        keys = { "filename" },
        types = {},
    },
}

function M.get_relative_path(filename)
    local cwd = vim.fn.getcwd()
    if not cwd:match "/$" then
        cwd = cwd .. "/"
    end
    if filename:sub(1, #cwd) == cwd then
        return filename:sub(#cwd + 1)
    end
    return filename
end

function M.parse_selection(selection, format)
    if not selection or selection == "" then
        return nil
    end

    local schema = schemas[format]
    if not schema then
        return nil
    end

    local patterns = type(schema.pattern) == "table" and schema.pattern or { schema.pattern }
    local matches = {}

    for _, pat in ipairs(patterns) do
        matches = { selection:match(pat) }
        if #matches > 0 then
            break
        end
    end

    if #matches == 0 then
        return nil
    end

    local result = {}
    for i, key in ipairs(schema.keys) do
        local val = matches[i]
        if val then
            if schema.types and schema.types[key] then
                val = schema.types[key](val)
            end
            result[key] = val
        end
    end

    result.lnum = result.lnum or 1
    result.col = result.col or 1

    return result
end

M.parsers = {
    file = function(selection)
        return M.parse_selection(selection, "file")
    end,
    grep = function(selection)
        return M.parse_selection(selection, "grep")
    end,
    lsp = function(selection)
        return M.parse_selection(selection, "lsp")
    end,
    buffer = function(selection)
        return M.parse_selection(selection, "buffer")
    end,
}

function M.jump_to_location(selection, data_or_format)
    local data = data_or_format

    if type(data_or_format) == "string" then
        data = M.parse_selection(selection, data_or_format)
    end

    if data and data.filename then
        vim.cmd("edit " .. vim.fn.fnameescape(data.filename))

        if data.lnum and data.col then
            vim.api.nvim_win_set_cursor(0, { data.lnum, data.col - 1 })
        end
    end
end

function M.get_line_content(filename, lnum)
    if vim.fn.filereadable(filename) == 0 then
        return ""
    end

    local bufnr = vim.fn.bufnr(filename)
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        local lines = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)
        return lines[1] or ""
    end

    local lines = vim.fn.readfile(filename, "", lnum)
    return lines[lnum] or ""
end

return M
