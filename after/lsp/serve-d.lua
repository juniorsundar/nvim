local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "serve-d" },
    filetypes = { "d" },
    root_markers = { "dub.json", "dub.sdl", ".git" },
    single_file_support = true,
    capabilities = capabilities,
}
