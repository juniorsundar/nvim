local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "neocmakelsp", "stdio" },
    filetypes = { "cmake" },
    capabilities = capabilities,
    single_file_support = true,
    root_markers = { ".git", "build", "cmake" },
}
