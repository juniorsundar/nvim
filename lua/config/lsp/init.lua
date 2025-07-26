require "config.lsp.servers"
require "config.lsp.keymaps"
require "config.lsp.hover"

-- LSPs ==========================================================
vim.lsp.enable {
  "lua-language-server",
  "basedpyright",
  "ruff",
  "clangd",
  "zls",
  "gopls",
  "rust-analyzer",
  "marksman",
  "docker-compose",
  "dockerfile",
  "serve-d",
}

