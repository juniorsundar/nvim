local capabilities = require "config.lsp.serve_capabilities"

vim.lsp.config["dockerfile"] = {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_markers = { "Dockerfile" },
  capabilities = capabilities,
}

vim.lsp.enable {
  "dockerfile",
}
