MiniDeps.later(function()
    MiniDeps.add { source = "mfussenegger/nvim-lint" }

    require("lint").linters_by_ft = {
        rust = { "clippy" },
        python = { "ruff" },
        lua = { "luacheck" },
    }

    vim.keymap.set({ "n" }, "<leader>LL", function()
        require("lint").try_lint()
    end, { desc = "Lint" })
end)
