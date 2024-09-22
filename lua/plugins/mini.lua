return {
    {
        "echasnovski/mini.pairs",
        event = "VeryLazy",
        config = function()
            require("mini.pairs").setup()
        end,
    },
    {
        "echasnovski/mini.ai",
        event = "VeryLazy",
        config = function()
            require("mini.ai").setup()
        end,
    },
    {
        "echasnovski/mini.move",
        event = "VeryLazy",
        config = function()
            require("mini.move").setup()
        end,
    },
    {
        "echasnovski/mini.jump",
        event = "VeryLazy",
        config = function()
            require("mini.jump").setup()
        end,
    },
}
