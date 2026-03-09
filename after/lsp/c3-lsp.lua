local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "c3-lsp" },
    filetypes = { "c3", "c3i" },
    root_markers = { "project.json", "manifest.json", ".git" },
    capabilities = capabilities,
}
