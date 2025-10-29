MiniDeps.add({ source = "stevearc/conform.nvim" })

require("conform").setup({
    formatters_by_ft = {
        c = { "clang-format" },
        python = { "ruff" },
        go = { "gofumpt" },
        rust = { "rustfmt" },
        nix = { "nixfmt" },
    },
})
