local M = {}
local minibuffer = require "minibuffer"
local util = require "minibuffer.util"

function M.commands()
    minibuffer.pick(function(input)
        if input == "" then
            return vim.fn.getcompletion("", "command")
        end
        return vim.fn.getcompletion(input, "cmdline")
    end, function(input_text)
        vim.cmd(input_text)
    end, { prompt = "M-x > " })
end

function M.buffers()
    local bufs = vim.api.nvim_list_bufs()
    local items = {}

    for _, bufnr in ipairs(bufs) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
            local name = vim.api.nvim_buf_get_name(bufnr)
            if name ~= "" then
                local relative_path = util.get_relative_path(name)
                local entry = string.format("%d: %s", bufnr, relative_path)
                table.insert(items, entry)
            end
        end
    end

    minibuffer.pick(items, function(selection)
        util.jump_to_location(selection)
    end, {
        prompt = "Buffers > ",
        keymaps = {
            ["<Tab>"] = "toggle_mark",
            ["<CR>"] = "select_entry",
        },
    })
end

return M
