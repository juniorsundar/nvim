require("micro.pack").add "gh:ydkulks/cursor-dark.nvim"
require("cursor-dark").setup {
    -- Set to `true` to make the background transparent
    transparent = false,
    -- Choose theme
    style = "dark",
}
vim.cmd [[colorscheme cursor-dark]]
