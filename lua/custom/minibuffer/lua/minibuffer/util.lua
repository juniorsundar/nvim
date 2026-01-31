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

function M.jump_to_location(selection)
    if not selection or selection == "" then
        return
    end

    local filename, lnum, col = selection:match "^(.*):(%d+):(%d+)$"

    if filename and lnum and col then
        vim.cmd("edit " .. filename)
        vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
    end
end

return M
