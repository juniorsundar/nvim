if not vim.g.vscode then
    return
end

require("micro").setup {
    pack = { enabled = true },
    split_suffix = { enabled = true },
}
