local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", ".git" },
    capabilities = capabilities,
    settings = {
        ["rust-analyzer"] = {
            cargo = {
                buildScripts = { enable = true },
                loadOutDirsFromCheck = true,
            },
            check = { workspace = true },
            lens = {
                enable = true,
                run = { enable = true },
                debug = { enable = true },
                implementations = { enable = true },
                references = { adt = { enable = true }, trait = { enable = true } },
            },
            inlayHints = {
                enable = true,
                typeHints = { enable = true },
                parameterHints = { enable = true },
                chainingHints = { enable = true },
            },
        },
    },
}
