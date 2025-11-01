MiniDeps.later(function()
	MiniDeps.add({ source = "folke/lazydev.nvim" })

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "lua",
		once = true,
		callback = function()
			require("lazydev").setup({
				library = {
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
					{ "nvim-dap-ui" },
					{ path = "snacks.nvim", words = { "Snacks" } },
					{ path = "lazy.nvim", words = { "LazyVim" } },
					{ path = "wezterm-types", mods = { "wezterm" } },
				},
			})
		end,
	})
end)
