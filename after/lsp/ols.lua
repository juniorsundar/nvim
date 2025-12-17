local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "ols" },
    filetypes = { "odin" },
    root_markers = { "ols.json", ".git" },
    capabilities = capabilities,
}
