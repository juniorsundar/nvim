return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			-- import nvim-treesitter plugin safely
			local status, treesitter = pcall(require, "nvim-treesitter.configs")
			if not status then
				return
			end

			-- configure treesitter
			treesitter.setup({
				-- enable syntax highlighting
				highlight = { enable = true, additional_vim_regex_highlighting = false },
				-- enable indentation
				indent = { enable = true },
				-- ensure these language parsers are installed
				ensure_installed = {
					"c",
					"cpp",
					"python",
					"yaml",
					"markdown",
					"markdown_inline",
					"bash",
					"lua",
					"vim",
					"rust",
					"vimdoc",
					"query",
					"norg",
				},
				-- auto install above language parsers
				auto_install = false,
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "gnn", -- set to `false` to disable one of the mappings
						node_incremental = "grn",
						scope_incremental = "grc",
						node_decremental = "grm",
					},
				},
			})
		end,
	},
}
