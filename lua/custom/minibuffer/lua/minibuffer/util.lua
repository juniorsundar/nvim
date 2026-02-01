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

    -- Try "filename:lnum:col" format (LSP)
    local filename, lnum, col = selection:match "^(.-):(%d+):(%d+)"
    if filename and lnum and col then
        return filename, tonumber(lnum), tonumber(col)
    end

    -- Try "bufnr: filename" format (Buffers)
    local bufnr_str, buf_filename = selection:match "^(%d+):%s+(.*)"
    if bufnr_str and buf_filename then
        return buf_filename, 1, 1
    end

    return nil, nil, nil
end

function M.jump_to_location(selection)
    local filename, lnum, col = M.parse_selection(selection)

    if filename then
        local bufnr = vim.fn.bufnr(filename)
        if bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
            vim.cmd("buffer " .. bufnr)
        else
            vim.cmd("edit " .. filename)
        end

        if lnum and col then
            vim.api.nvim_win_set_cursor(0, { lnum, col - 1 })
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
