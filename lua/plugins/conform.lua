return {
    "stevearc/conform.nvim",
    enabled = true,
    event = "LspAttach",
    opts = {
        formatters_by_ft = {
            c = { "clang-format" },
            python = { "ruff" },
            go = { "gofumpt" },
            rust = { "rustfmt" },
            nix = { "nixfmt" },
        },
    },
}
