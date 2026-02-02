local M = {}
local minibuffer = require "minibuffer"
local util = require "minibuffer.util"

function M.files()
    local files_list = {}

    local fd_result = vim.system({ "fd", "-H" }, { text = true }):wait()
    files_list = vim.split(fd_result.stdout, "\n", { trimempty = true })
    minibuffer.pick(files_list, util.jump_to_location, {
        prompt = "Files > ",
        keymaps = {
            ["<Tab>"] = "toggle_mark",
            ["<CR>"] = "select_entry",
        },
        selection_format = "file",
    })
end

return M
