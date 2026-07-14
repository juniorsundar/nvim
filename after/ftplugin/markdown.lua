vim.opt.conceallevel = 2
vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

vim.lsp.enable {
    "marksman",
    "markdown_oxide",
}
