vim.keymap.set("n", "<leader>L", "", { noremap = false, silent = true, desc = "LSP" })
vim.keymap.set("n", "<leader>LA", "", { noremap = false, silent = true, desc = "DAP" })
vim.keymap.set("n", "<leader>LD", "", { noremap = false, silent = true, desc = "Document" })
vim.keymap.set("n", "<leader>LI", "<cmd>checkhealth lsp<cr>", { noremap = false, silent = true, desc = "LSP Info" })

vim.keymap.set("n", "<leader>La", function()
  vim.lsp.buf.code_action()
end, { noremap = false, silent = true, desc = "Code Action" })
vim.keymap.set("n", "<leader>Lf", function()
  vim.lsp.buf.format { async = true }
end, { noremap = false, silent = true, desc = "Format" })
vim.keymap.set("n", "<leader>Ll", function()
  vim.lsp.codelens.run()
end, { noremap = false, silent = true, desc = "CodeLens Action" })
vim.keymap.set("n", "<leader>Ln", function()
  vim.lsp.buf.rename()
end, { noremap = false, silent = true, desc = "Rename" })
vim.keymap.set("n", "<leader>Lk", function()
  vim.lsp.buf.hover { border = "rounded" }
end, { noremap = false, silent = true, desc = "Hover" })

vim.keymap.set("n", "<leader>LW", "", { noremap = false, silent = true, desc = "Workspace" })
vim.keymap.set("n", "<leader>LWa", function()
  vim.lsp.buf.add_workspace_folder()
end, { noremap = false, silent = true, desc = "Add Workspace Folder" })
vim.keymap.set("n", "<leader>LWr", function()
  vim.lsp.buf.remove_workspace_folder()
end, { noremap = false, silent = true, desc = "Remove Workspace Folder" })
vim.keymap.set("n", "<leader>LWl", function()
  vim.lsp.buf.list_workspace_folders()
end, { noremap = false, silent = true, desc = "List Workspace Folders" })

vim.keymap.set("n", "<leader>Ld", "", { noremap = false, silent = true, desc = "Definition" })
vim.keymap.set("n", "<leader>Lc", "", { noremap = false, silent = true, desc = "Declaration" })
vim.keymap.set("n", "<leader>Li", "", { noremap = false, silent = true, desc = "Implementation" })

vim.keymap.set(
  "n",
  "<leader>Ldd",
  "<cmd>lua vim.lsp.buf.definition()<cr>",
  { noremap = false, silent = true, desc = "Goto" }
)
vim.keymap.set(
  "n",
  "<leader>Lcc",
  "<cmd>lua vim.lsp.buf.declaration()<cr>",
  { noremap = false, silent = true, desc = "Goto" }
)
vim.keymap.set(
  "n",
  "<leader>Lii",
  "<cmd>lua vim.lsp.buf.implementation()<cr>",
  { noremap = false, silent = true, desc = "Goto" }
)

vim.keymap.set(
  "n",
  "<leader>Lds",
  "<cmd>split | lua vim.lsp.buf.definition()<cr>",
  { noremap = false, silent = true, desc = "Horizontal Split" }
)
vim.keymap.set(
  "n",
  "<leader>Lcs",
  "<cmd>split | lua vim.lsp.buf.declaration()<cr>",
  { noremap = false, silent = true, desc = "Horizontal Split" }
)
vim.keymap.set(
  "n",
  "<leader>Lis",
  "<cmd>split | lua vim.lsp.buf.implementation()<cr>",
  { noremap = false, silent = true, desc = "Horizontal Split" }
)

vim.keymap.set(
  "n",
  "<leader>Ldv",
  "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>",
  { noremap = false, silent = true, desc = "Vertical Split" }
)
vim.keymap.set(
  "n",
  "<leader>Lcv",
  "<cmd>vsplit | lua vim.lsp.buf.declaration()<cr>",
  { noremap = false, silent = true, desc = "Vertical Split" }
)
vim.keymap.set(
  "n",
  "<leader>Liv",
  "<cmd>vsplit | lua vim.lsp.buf.implementation()<cr>",
  { noremap = false, silent = true, desc = "Vertical Split" }
)
