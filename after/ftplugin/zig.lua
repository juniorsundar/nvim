vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require("config.lsp.serve_capabilities")

vim.lsp.config["zls"] = {
	cmd = { "zls" },
	filetypes = { "zig" },
	root_markers = { "zls.json", "build.zig", ".git" },
	single_file_support = true,
	capabilities = capabilities,
}

vim.lsp.enable({
	"zls",
})
