local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "zc", "lsp" },
    filetypes = { "zenc", "zc" },
    root_markers = { "build.bat", "Makefile", ".git" },
    capabilities = capabilities,
    settings = {},
}
