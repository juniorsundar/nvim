vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

vim.lsp.enable {
    "lua-language-server",
}
