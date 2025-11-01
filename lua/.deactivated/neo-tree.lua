return {
	"nvim-neo-tree/neo-tree.nvim",
	enabled = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
	},
	lazy = false,
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle position=right<cr>", desc = "Toggle Neotree" },
	},
	opts = {
		filesystem = {
			hijack_netrw_behavior = "disabled",
			filtered_items = {
				hide_dotfiles = false,
				hide_hidden = false,
			},
		},
	},
}
