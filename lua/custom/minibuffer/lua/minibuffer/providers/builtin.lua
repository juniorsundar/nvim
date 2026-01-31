local M = {}
local minibuffer = require "minibuffer"

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

return M
