local M = {
    source = "stevearc/conform.nvim",
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                c = { "clang-format" },
                python = { "ruff" },
                go = { "gofumpt" },
                rust = { "rustfmt" },
                nix = { "nixfmt" },
            },
        })
    end
}

return M
