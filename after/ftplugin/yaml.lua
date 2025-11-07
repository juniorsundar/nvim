local capabilities = require "config.lsp.serve_capabilities"

vim.lsp.config["docker-compose"] = {
    cmd = { "docker-compose-langserver", "--stdio" },
    filetypes = { "yaml" },
    root_markers = { "docker-compose.yaml", "docker-compose.yml", "compose.yaml", "compose.yml" },
    capabilities = capabilities,
}

vim.lsp.enable {
    "docker-compose",
}
