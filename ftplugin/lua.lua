vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require "config.lsp.serve_capabilities"

vim.lsp.config["lua-language-server"] = {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = {
          "${3rd}/luv/library",
          unpack(vim.api.nvim_get_runtime_file("", true)),
        },
      },
      completion = {
        callSnippet = "Replace",
      },
      hint = {
        enable = true,
      },
    },
  },
}

vim.lsp.enable {
  "lua-language-server",
}
