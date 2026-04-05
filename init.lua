-- OPTIONS ==========================================================
vim.g.mapleader = " "
vim.g.maplocalleader = "  "
vim.keymap.set({ "n", "v" }, "<leader>", "", { desc = "Leader", noremap = false, silent = true })
vim.keymap.set({ "n", "v" }, "<leader><leader>", "", { desc = "LocalLeader", noremap = false, silent = true })

vim.opt.clipboard = "unnamedplus"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.mouse = "a"

-- Tab
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- UI config
vim.opt.cursorline = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.showmode = false
vim.opt.showtabline = 0

-- Searching
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = "split"

vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 0

vim.o.grepprg = "rg --vimgrep"
vim.o.grepformat = "%f:%l:%c:%m"
vim.o.foldlevel = 0
vim.cmd [[set fillchars+=eob:\ ]]

vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
        local line = vim.fn.line "'\""
        if
            line > 1
            and line <= vim.fn.line "$"
            and vim.bo.filetype ~= "commit"
            and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
        then
            vim.cmd 'normal! g`"'
        end
    end,
})

vim.loader.enable()

-- require("vim._core.ui2").enable {}
vim.g.difftool = true
vim.cmd.packadd "nvim.difftool"

vim.g.undotree = true
vim.cmd.packadd "nvim.undotree"

-- KEYMAPS ==========================================================
-- define common options
local opts = {
    noremap = true, -- non-recursive
    silent = true, -- do not show message
}

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

-- Visual mode --
vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)
-- Terminal mode --
vim.keymap.set("t", "<C-\\><C-\\>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- PLUGINS ==========================================================
if vim.g.vscode then
    require "plugins"
else
    -- Custom local plugins
    vim.opt.rtp:prepend(vim.fn.stdpath "config" .. "/lua/custom/refer.nvim")
    vim.opt.rtp:prepend(vim.fn.stdpath "config" .. "/lua/custom/cling.nvim")
    vim.opt.rtp:prepend(vim.fn.stdpath "config" .. "/lua/custom/buffers.nvim")
    vim.opt.rtp:prepend(vim.fn.stdpath "config" .. "/lua/custom/micro.nvim")

    require "plugins"

    -- LSP ======================================================
    require "config.lsp"

    -- MISC UTILS ===============================================
    require "config.utils"
end
