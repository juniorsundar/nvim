local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "docker-langserver", "--stdio" },
    filetypes = { "dockerfile" },
    root_markers = { "Dockerfile" },
    capabilities = capabilities,
}

