if not vim.g.vscode then
    return
end

require("micro").setup {
    split_suffix = { enabled = true },
}
