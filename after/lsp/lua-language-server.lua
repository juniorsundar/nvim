local capabilities = require "config.lsp.serve_capabilities"

local root_markers1 = {
    ".git",
    ".emmyrc.json",
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
}

return {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = root_markers1,
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
