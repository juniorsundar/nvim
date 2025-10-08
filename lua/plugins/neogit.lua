return {
    "NeogitOrg/neogit",
    enabled = true,
    keys = {
        { "<leader>Gg", "<cmd>Neogit<cr>",           { desc = "Neogit" } },
        { "<leader>G.", "<cmd>Neogit cwd=%:p:h<cr>", { desc = "Open to CWD" } }
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
