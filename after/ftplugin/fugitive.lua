local fugitive_augroup = vim.api.nvim_create_augroup("FugitiveSettings", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
	group = fugitive_augroup,
	pattern = "fugitive://*",
	callback = function()
		vim.opt.number = false
		vim.opt.relativenumber = false
	end,
})

vim.api.nvim_create_autocmd("BufLeave", {
	group = fugitive_augroup,
	pattern = "fugitive://*",
	callback = function()
		vim.opt.number = true
		vim.opt.relativenumber = true
	end,
})
