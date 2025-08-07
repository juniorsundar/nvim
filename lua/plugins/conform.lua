return {
  "stevearc/conform.nvim",
  enabled = true,
  event = "LspAttach",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff" },
      go = { "gofumpt" },
      rust = { "rustfmt" },
    },
  },
}
