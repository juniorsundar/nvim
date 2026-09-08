local capabilities = require "config.lsp.serve_capabilities"

local root_markers1 = {
    ".emmyrc.json",
    ".luarc.json",
    ".luarc.jsonc",
}
local root_markers2 = {
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
}

return {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = vim.fn.has "nvim-0.11.3" == 1 and { root_markers1, root_markers2, { ".git" } }
        or vim.list_extend(vim.list_extend(root_markers1, root_markers2), { ".git" }),
    capabilities = capabilities,
    settings = {
        Lua = {
            hint = {
                enable = true,
            },
            codeLens = {
                enable = true,
            },
        },
    },
}
