vim.g.mapleader = vim.api.nvim_replace_termcodes("<A-Space>", true, true, true)
vim.g.mapleader = " "
vim.g.maplocalleader = "  "

-- Hint: use `:h <option>` to figure out the meaning if needed
vim.opt.clipboard = "unnamedplus" -- use system clipboard
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.mouse = "a" -- allow the mouse to be used in Nvim

-- Tab
vim.opt.tabstop = 4 -- number of visual spaces per TAB
vim.opt.softtabstop = 4 -- number of spacesin tab when editing
vim.opt.shiftwidth = 4 -- insert 4 spaces on a tab
vim.opt.expandtab = true -- tabs are spaces, mainly because of python

-- UI config
vim.opt.number = true -- show absolute number
vim.opt.relativenumber = true -- add numbers to each line on the left side
vim.opt.cursorline = true -- highlight cursor line underneath the cursor horizontally
vim.opt.splitbelow = true -- open new vertical split bottom
vim.opt.splitright = true -- open new horizontal splits right
vim.opt.termguicolors = true -- enabl 24-bit RGB color in the TUI
vim.opt.showmode = false -- we are experienced, wo don't need the "-- INSERT --" mode hint

-- Searching
vim.opt.incsearch = true -- search as characters are entered
vim.opt.hlsearch = false -- do not highlight matches
vim.opt.ignorecase = true -- ignore case in searches by default
vim.opt.smartcase = true -- but make it case sensitive if an uppercase is entered
vim.opt.inccommand = "split" -- shows how certain commands apply in a separate window

vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 10

vim.o.grepprg = "rg --vimgrep"
vim.o.grepformat = "%f:%l:%c:%m"

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	callback = function()
		local line = vim.fn.line("'\"")
		if
			line > 1
			and line <= vim.fn.line("$")
			and vim.bo.filetype ~= "commit"
			and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
		then
			vim.cmd('normal! g`"')
		end
	end,
})
