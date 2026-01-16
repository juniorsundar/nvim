local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "clangd" },
    filetypes = { "cpp", "hpp", "h", "c", "cuda" },
    root_markers = { "compile_commands.json", ".clangd" },
    capabilities = capabilities,
}
