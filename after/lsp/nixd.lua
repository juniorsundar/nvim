local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "nixd" },
    filetypes = { "nix" },
    root_markers = { "flake.nix", ".git" },
    single_file_support = true,
    capabilities = capabilities,
}
