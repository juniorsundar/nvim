MiniDeps.later(function()
	MiniDeps.add({ source = "mfussenegger/nvim-lint" })
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = "*",
		once = true,
		callback = function()
			require("lint").linters_by_ft = {
				rust = { "clippy" },
			}
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		callback = function()
			require("lint").try_lint()
		end,
	})
end)
