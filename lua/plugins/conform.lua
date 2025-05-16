return {
    "stevearc/conform.nvim",
    enabled = true,
    event = "VeryLazy",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "ruff" },
            go = { "gofumpt" },
        },
    },
}
