local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "v-analyzer" },
    filetypes = { "v", "vsh", "vv" },
    root_markers = { "v.mod", ".git" },
    capabilities = capabilities,
}
