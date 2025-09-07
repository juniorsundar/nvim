vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require "config.lsp.serve_capabilities"

vim.lsp.config["marksman"] = {
    cmd = { "marksman" },
    filetypes = { "markdown" },
    root_markers = { ".marksman.toml", ".git" },
    single_file_support = true,
    capabilities = capabilities,
}

vim.lsp.enable {
    "marksman",
}
