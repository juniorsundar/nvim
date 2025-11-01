vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require("config.lsp.serve_capabilities")

vim.lsp.config["clangd"] = {
	cmd = { "clangd" },
	filetypes = { "cpp", "hpp", "h", "c", "cuda" },
	root_markers = { "compile_commands.json", ".clangd", ".git" },
	capabilities = capabilities,
}

vim.lsp.enable({
	"clangd",
})
