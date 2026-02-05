if vim.g.loaded_minibuffer == 1 then
    return
end
vim.g.loaded_minibuffer = 1

local subcommands = {
    Files = function()
        require("minibuffer.providers.files").files()
    end,
    Grep = function()
        require("minibuffer.providers.files").live_grep()
    end,
    Buffers = function()
        require("minibuffer.providers.builtin").buffers()
    end,
    OldFiles = function()
        require("minibuffer.providers.builtin").old_files()
    end,
    Commands = function()
        require("minibuffer.providers.builtin").commands()
    end,
    References = function()
        require("minibuffer.providers.lsp").references()
    end,
    Definitions = function()
        require("minibuffer.providers.lsp").definitions()
    end,
}

vim.api.nvim_create_user_command("Minibuffer", function(opts)
    local subcommand_key = opts.fargs[1]
    local func = subcommands[subcommand_key]
    if func then
        func()
    else
        vim.notify("Minibuffer: Unknown subcommand: " .. subcommand_key, vim.log.levels.ERROR)
    end
end, {
    nargs = 1,
    complete = function(ArgLead, CmdLine, CursorPos)
        local keys = vim.tbl_keys(subcommands)
        table.sort(keys)
        return vim.tbl_filter(function(key)
            return key:find(ArgLead, 1, true) == 1
        end, keys)
    end,
})
