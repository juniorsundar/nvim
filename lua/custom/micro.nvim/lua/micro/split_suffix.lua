local M = {}
local ns_id = vim.api.nvim_create_namespace "split_suffix_beacon"

local default = {
    modifiers = {
        ["vsplit"] = "<C-v>",
        ["split"] = "<C-h>",
    },
}

local function split_suffix(command)
    local buf_dest = vim.api.nvim_get_current_buf()
    local line_dest = vim.api.nvim_win_get_cursor(0)[1] - 1

    vim.cmd(command)

    vim.cmd "wincmd p"
    vim.cmd [[execute "normal! \<C-o>"]]

    local buf_orig = vim.api.nvim_get_current_buf()
    local line_orig = vim.api.nvim_win_get_cursor(0)[1] - 1

    vim.api.nvim_buf_clear_namespace(buf_dest, ns_id, 0, -1)
    vim.api.nvim_buf_clear_namespace(buf_orig, ns_id, 0, -1)

    vim.api.nvim_buf_set_extmark(buf_dest, ns_id, line_dest, 0, { line_hl_group = "IncSearch" })
    vim.api.nvim_buf_set_extmark(buf_orig, ns_id, line_orig, 0, { line_hl_group = "IncSearch" })

    vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(buf_dest) then
            vim.api.nvim_buf_clear_namespace(buf_dest, ns_id, line_dest, line_dest + 1)
        end
        if vim.api.nvim_buf_is_valid(buf_orig) then
            vim.api.nvim_buf_clear_namespace(buf_orig, ns_id, line_orig, line_orig + 1)
        end
    end, 1000)
end

function M.setup(opts)
    default = vim.tbl_deep_extend("force", default, opts or {})

    vim.keymap.set("n", default.modifiers.vsplit, function()
        split_suffix "vsplit"
    end)
    vim.keymap.set("n", default.modifiers.split, function()
        split_suffix "split"
    end)
end

return M
