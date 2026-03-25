local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "gleam", "lsp" },
    filetypes = { "gleam" },
    root_markers = { "gleam.toml", ".git" },
    capabilities = capabilities,
}
