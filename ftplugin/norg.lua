vim.api.nvim_create_autocmd("InsertEnter", {
	pattern = "*.norg",
	group = vim.api.nvim_create_augroup("NeorgWrapOn", { clear = true }),
	callback = function(_)
		vim.cmd("set wrap")
	end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*.norg",
	group = vim.api.nvim_create_augroup("NeorgWrapOff", { clear = true }),
	callback = function(_)
		vim.cmd("set nowrap")
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.norg",
	group = vim.api.nvim_create_augroup("NeorgWrapOffBuf", { clear = true }),
	callback = function(_)
		vim.cmd("set nowrap")
	end,
})

vim.api.nvim_create_autocmd("BufLeave", {
	pattern = "*.norg",
	group = vim.api.nvim_create_augroup("NeorgWrapOnBuf", { clear = true }),
	callback = function(_)
		vim.cmd("set wrap")
	end,
})
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.norg" },
	callback = function(ev)
		vim.opt_local.conceallevel = 2
		vim.wo.foldlevel = 1
	end,
})

vim.opt.scrolloff = 999
