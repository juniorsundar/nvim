return
{
    "NeogitOrg/neogit",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    keys = {
        { "<leader>Gg", "<cmd>Neogit cwd=%:p:h<cr>", desc = "Neogit" },
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
    end,
}
