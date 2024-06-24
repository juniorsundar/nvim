-- define common options
local opts = {
	noremap = false, -- non-recursive
	silent = true, -- do not show message
}

-----------------
-- Normal mode --
-----------------

-- Hint: see `:h vim.map.set()`
-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)
-- Resize with arrows
-- delta: 2 lines
vim.keymap.set("n", "<C-A-Up>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<C-A-Down>", ":resize +2<CR>", opts)
vim.keymap.set("n", "<C-A-Left>", ":vertical resize -2<CR>", opts)
vim.keymap.set("n", "<C-A-Right>", ":vertical resize +2<CR>", opts)

vim.keymap.set("n", "<C-Right>", "w", opts)
vim.keymap.set("n", "<C-Left>", "b", opts)
vim.keymap.set("n", "<C-Up>", "gk", opts)
vim.keymap.set("n", "<C-Down>", "gj", opts)

vim.keymap.set("n", "<S-A-Up>", "<cmd>m .-2<CR>==", opts)
vim.keymap.set("n", "<S-A-Down>", "<cmd>m .+1<CR>==", opts)

vim.keymap.set("n", "gb", "<cmd>bnext<CR>", {noremap = false, silent = true, desc = "Next buffer"})
vim.keymap.set("n", "gB", "<cmd>bprevious<CR>", {noremap = false, silent = true, desc = "Previous buffer"})

-----------------
-- Visual mode --
-----------------

-- Hint: start visual mode with the same area as the previous area and the same mode
vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

-----------------
-- Terminal mode --
-----------------

vim.keymap.set('t', '<C-\\><C-\\>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
