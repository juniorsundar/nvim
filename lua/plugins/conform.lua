MiniDeps.later(function()
    MiniDeps.add({ source = "stevearc/conform.nvim" })
    vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*",
        once = true,
        callback = function()
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
    })
end)
