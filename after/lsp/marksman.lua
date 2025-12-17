local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "marksman" },
    filetypes = { "markdown" },
    root_markers = { ".marksman.toml", ".git" },
    single_file_support = true,
    capabilities = capabilities,
}
