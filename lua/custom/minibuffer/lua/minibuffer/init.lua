local Picker = require "minibuffer.picker"

local M = {}
local default_opts = {}

function M.setup(opts)
    default_opts = opts or {}
end

function M.pick(items_or_provider, on_select, opts)
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})
    if on_select then
        opts.on_select = on_select
    end

    local picker = Picker.new(items_or_provider, opts)
    picker:show()
end

return M
