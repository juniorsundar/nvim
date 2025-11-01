vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require("config.lsp.serve_capabilities")

vim.lsp.config["nixd"] = {
	cmd = { "nixd" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", ".git" },
	single_file_support = true,
	capabilities = capabilities,
}

vim.lsp.enable({
	"nixd",
})
