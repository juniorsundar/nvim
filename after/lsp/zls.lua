local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "zls" },
    filetypes = { "zig" },
    root_markers = { "zls.json", "build.zig", ".git" },
    single_file_support = true,
    capabilities = capabilities,
}
