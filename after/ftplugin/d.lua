vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require("config.lsp.serve_capabilities")

vim.lsp.config["serve-d"] = {
	cmd = { "serve-d" },
	filetypes = { "d" },
	root_markers = { "dub.json", "dub.sdl", ".git" },
	single_file_support = true,
	capabilities = capabilities,
}

vim.lsp.enable({
	"serve-d",
})
