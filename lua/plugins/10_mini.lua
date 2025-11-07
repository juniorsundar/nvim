MiniDeps.add { source = "nvim-mini/mini.ai" }
MiniDeps.add { source = "nvim-mini/mini.move" }
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    once = true,
    callback = function()
        require("mini.ai").setup {
            n_lines = 500,
        }

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
