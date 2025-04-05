return {
    {
        "echasnovski/mini.pairs",
        event = "VeryLazy",
        config = function()
            require("mini.pairs").setup({
                modes = { insert = true, command = true, terminal = false },
                -- skip autopair when next character is one of these
                skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
                -- skip autopair when the cursor is inside these treesitter nodes
                skip_ts = { "string" },
                -- skip autopair when next character is closing pair
                -- and there are more closing pairs than opening pairs
                skip_unbalanced = true,
                -- better deal with markdown code blocks
                markdown = true,
            })
        end,
    },
    {
        "echasnovski/mini.ai",
        event = "VeryLazy",
        config = function()
            local ai = require("mini.ai")
            ai.setup({
                n_lines = 500,
            })
        end,
    },
    {
        "echasnovski/mini.move",
        event = "VeryLazy",
        config = function()
            require("mini.move").setup()
        end,
    }
}
