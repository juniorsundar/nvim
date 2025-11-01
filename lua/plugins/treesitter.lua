MiniDeps.now(function()
	MiniDeps.add({
		source = "nvim-treesitter/nvim-treesitter",
		checkout = "main",
		hooks = {
			post_checkout = function()
				vim.cmd("TSUpdate")
			end,
		},
	})
	require("nvim-treesitter").install({
		"rust",
		"c3",
		"c",
		"cpp",
		"javascript",
		"python",
		"lua",
		"yaml",
		"markdown",
		"nix",
		"json",
		"toml",
		"go",
		"gomod",
		"zig",
		"d",
	})

	vim.api.nvim_create_autocmd("FileType", {
		pattern = {
			"rust",
			"c3",
			"c",
			"cpp",
			"javascript",
			"python",
			"lua",
			"yaml",
			"markdown",
			"nix",
			"json",
			"toml",
			"go",
			"gomod",
			"zig",
			"d",
			"odin",
		},
		callback = function()
			vim.treesitter.start()
			vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		end,
	})
end)
