return {
    "NeogitOrg/neogit",
    enabled = true,
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("neogit").setup {
            disable_hint = true,
            signs = {
                hunk = { "", "" },
                item = { "", "" },
                section = { "", "" },
            },
            graph_style = "unicode",
            integrations = {
                telescope = nil,
                diffview = true,
                fzf_lua = nil,
                mini_pick = nil,
                snacks = true,
            },
        }
        vim.keymap.set("n", "<leader>Gg", "<cmd>Neogit<cr>", { desc = "Neogit" })
        vim.keymap.set("n", "<leader>G.", "<cmd>Neogit cwd=%:p:h<cr>", { desc = "Open to CWD" })
    end,
}
