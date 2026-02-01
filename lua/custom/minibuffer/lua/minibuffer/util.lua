local M = {}

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

function M.parse_selection(selection)
    if not selection or selection == "" then
        return nil, nil, nil
    end

    local filename, lnum, col = selection:match "^(.-):(%d+):(%d+)"
    if filename and lnum and col then
        return filename, tonumber(lnum), tonumber(col)
    end
    return nil, nil, nil
end

function M.jump_to_location(selection)
    local filename, lnum, col = M.parse_selection(selection)
    if filename then
        vim.cmd("edit " .. filename)
        vim.api.nvim_win_set_cursor(0, { lnum, col - 1 })
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
