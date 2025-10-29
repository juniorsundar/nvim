MiniDeps.now(
    function()
        MiniDeps.add({ source = "nvim-mini/mini.ai" })
        require("mini.ai").setup({
            n_lines = 500,
        })

        MiniDeps.add({ source = "nvim-mini/mini.move" })
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
