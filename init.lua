-- OPTIONS ==========================================================
vim.g.mapleader = " "
vim.g.maplocalleader = "  "
vim.opt.clipboard = "unnamedplus"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.mouse = "a"

-- Tab
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- UI config
vim.opt.number = true
vim.opt.relativenumber = true
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

-- KEYMAPS ==========================================================
-- define common options
local opts = {
    noremap = false, -- non-recursive
    silent = true,   -- do not show message
}

-- Normal mode --
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

-- Visual mode --
vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

-- Terminal mode --
vim.keymap.set("t", "<C-\\><C-\\>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- COLORSCHEME ======================================================
require("theme").set_colorscheme()

-- PLUGINS ==========================================================
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.deps'
if not vim.loop.fs_stat(mini_path) then
    vim.cmd('echo "Installing `mini.deps`" | redraw')
    local clone_cmd = {
        'git', 'clone', '--filter=blob:none',
        'https://github.com/nvim-mini/mini.deps', mini_path
    }
    vim.fn.system(clone_cmd)
    vim.cmd('packadd mini.deps | helptags ALL')
    vim.cmd('echo "Installed `mini.deps`" | redraw')
end
require('mini.deps').setup({ path = { package = path_package } })

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

now(
    function()
        add({ source = "nvim-tree/nvim-web-devicons" })

        add({ source = require("plugins.which-key").source })
        require("plugins.which-key").config()

        add({ source = require("plugins.snacks").source })
        require("plugins.snacks").config()

        add({ source = require("plugins.lualine").source })
        require("plugins.lualine").config()

        add({ source = require("plugins.oil").source })
        require("plugins.oil").config()

        add({
            source = require("plugins.blink").source,
            checkout = require("plugins.blink").checkout,
            monitor = "main"
        })
        require("plugins.blink").config()

        add({
            source = require("plugins.treesitter").source,
            checkout = require("plugins.treesitter").checkout,
            hooks = {
                post_checkout = require("plugins.treesitter").post_checkout
            }
        })
        require("plugins.treesitter").config()

        add({ source = require("plugins.nvim-surround").source })
        require("plugins.nvim-surround").config()

        add({ source = "nvim-mini/mini.ai" })
        require("mini.ai").setup({
            n_lines = 500,
        })

        add({ source = "nvim-mini/mini.move" })
        require("mini.move").setup({
            mappings = {
                left = "<S-left>",
                right = "<S-right>",
                down = "<S-down>",
                up = "<S-up>",
                line_left = "<S-left>",
                line_right = "<S-right>",
                line_down = "<S-down>",
                line_up = "<S-up>",
            },
        })
    end
)

later(
    function()
        add({ source = require("plugins.mason").source })
        require("plugins.mason").config()

        add({ source = require("plugins.conform").source })
        require("plugins.conform").config()

        add({ source = require("plugins.lazydev").source })
        require("plugins.lazydev").config()

        add({ source = require("plugins.diffview").source })
        require("plugins.diffview").config()

        add({ source = require("plugins.gitsigns").source })
        require("plugins.gitsigns").config()

        add({ source = require("plugins.vim-fugitive").source })
        require("plugins.vim-fugitive").config()

        add({ source = require("plugins.flash").source })
        require("plugins.flash").config()

        add({ source = require("plugins.quicker").source })
        require("plugins.quicker").config()

        add({ source = require("plugins.render-markdown").source, depends = require("plugins.render-markdown").depends })
        require("plugins.render-markdown").config()
    end
)

require "config.lsp"
