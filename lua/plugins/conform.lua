return {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "ruff" },
            go = { "gofumpt" },
        },
    },
}
