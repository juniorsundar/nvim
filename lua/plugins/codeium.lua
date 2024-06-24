return {
	"Exafunction/codeium.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"hrsh7th/nvim-cmp",
	},
    event = "LspAttach",
	config = function()
		require("codeium").setup({})
	end,
}
