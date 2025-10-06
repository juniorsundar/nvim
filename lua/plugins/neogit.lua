return {
    "NeogitOrg/neogit",
    enabled = true,
    keys = {
        { "<leader>Gg", "<cmd>Neogit<cr>", { desc = "Neogit" } },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    opts = {
        disable_hint = true,
        signs = {
            hunk = { "", "" },
            item = { "", "" },
            section = { "", "" },
        },
        graph_style = "unicode",
        integrations = {
            telescope = false,
            diffview = true,
            fzf_lua = false,
            mini_pick = false,
            snacks = true,
        },
    }
}
