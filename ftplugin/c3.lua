vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require "config.lsp.serve_capabilities"

vim.lsp.config["c3-lsp"] = {
  cmd = { "c3lsp" },
  filetypes = { "c3", "c3i" },
  root_markers = { 'project.json', 'manifest.json', '.git' },
  capabilities = capabilities,
}

vim.lsp.enable {
  "c3-lsp",
}

