vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

vim.lsp.enable {
    "marksman",
}

local markview_present, _ = pcall(require, "markview")
if markview_present then
    vim.cmd[[Markview HybridEnable]]
end
