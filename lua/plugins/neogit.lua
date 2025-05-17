return {
    "NeogitOrg/neogit",
    enabled = false,
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
            },
        }

        vim.keymap.set('n', "<leader>Gg", "<cmd>Neogit cwd=%:p:h<cr>", { desc = "Neogit" })
    end,
}
