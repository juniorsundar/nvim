vim.pack.add { "https://github.com/nvim-mini/mini.move" }

vim.api.nvim_create_autocmd("BufEnter", {
    once = true,
    callback = function()
        require("mini.move").setup {
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
        }
    end,
})
