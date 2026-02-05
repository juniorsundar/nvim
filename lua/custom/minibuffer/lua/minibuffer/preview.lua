local api = vim.api
local util = require "minibuffer.util"

local M = {}

---@class PreviewOpts
---@field filename string
---@field lnum? number
---@field col? number
---@field target_win number

---Show preview in the target window
---@param opts PreviewOpts
function M.show(opts)
    local filename = opts.filename
    local lnum = opts.lnum or 1
    local col = opts.col or 1
    local target_win = opts.target_win

    if not api.nvim_win_is_valid(target_win) then
        return
    end

    api.nvim_win_call(target_win, function()
        local bufnr = vim.fn.bufnr(filename)

        -- Reuse existing loaded buffer if possible
        if bufnr ~= -1 and api.nvim_buf_is_loaded(bufnr) then
            if api.nvim_win_get_buf(target_win) ~= bufnr then
                api.nvim_win_set_buf(target_win, bufnr)
            end
        else
            -- Create a temporary preview buffer
            local buf = api.nvim_create_buf(false, true)
            vim.bo[buf].bufhidden = "wipe"
            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].swapfile = false

            local existing = vim.fn.bufnr(filename)
            if existing == -1 then
                pcall(api.nvim_buf_set_name, buf, filename)
            else
                pcall(api.nvim_buf_set_name, buf, filename .. " (Preview)")
            end

            if util.is_binary(filename) then
                api.nvim_buf_set_lines(buf, 0, -1, false, { "[Binary File - Preview Disabled]" })
            else
                local lines = {}
                if vim.fn.filereadable(filename) == 1 then
                    lines = vim.fn.readfile(filename, "", 1000)
                end

                for i, line in ipairs(lines) do
                    if line:find "[\r\n]" then
                        lines[i] = line:gsub("[\r\n]", " ")
                    end
                end

                api.nvim_buf_set_lines(buf, 0, -1, false, lines)

                local ft = vim.filetype.match { filename = filename }
                if ft then
                    vim.bo[buf].filetype = ft
                end
            end

            api.nvim_win_set_buf(target_win, buf)
        end

        if lnum and col then
            pcall(api.nvim_win_set_cursor, target_win, { lnum, col - 1 })
            vim.cmd "normal! zz"
        end
    end)
end

return M
