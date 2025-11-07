vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require "config.lsp.serve_capabilities"

vim.lsp.config["ols"] = {
    cmd = { "ols" },
    filetypes = { "odin" },
    root_markers = { "ols.json", ".git" },
    capabilities = capabilities,
}

vim.lsp.enable {
    "ols",
}
