vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require "config.lsp.serve_capabilities"

vim.lsp.config["rust-analyzer"] = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", ".git" },
    -- single_file_support = true,
    capabilities = capabilities,
}

vim.lsp.enable {
    "rust-analyzer",
}
