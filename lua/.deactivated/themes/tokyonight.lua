require("micro.pack").add { src = "gh:folke/tokyonight.nvim", name = "tokyonight" }
require("tokyonight").setup {
    cache = true,
    plugins = {
        all = true,
    },
}

vim.cmd [[colorscheme tokyonight]]
