return {
    {
        "nvim-mini/mini.ai",
        event = "VeryLazy",
        config = function()
            local ai = require "mini.ai"
            ai.setup {
                n_lines = 500,
            }
        end,
    },
    {
        "nvim-mini/mini.move",
        event = "VeryLazy",
        config = function()
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
    },
}
