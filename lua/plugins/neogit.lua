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

        vim.keymap.set('n', "<leader>Gg", "<cmd>Neogit<cr>", { desc = "Neogit" })
    end,
}
