return {
    "NeogitOrg/neogit",
    branch = "master",
    dependencies = {
        "nvim-lua/plenary.nvim",      -- required
    },
    config = function()
        local neogit = require("neogit")
        neogit.setup({
            disable_hint = true,
            graph_style = "unicode",
            kind = "split",
            disable_signs = false,
            signs = {
                hunk = { "", "" },
                item = { "", "" },
                section = { "", "" },
            },
            integrations = {
                diffview = true,
                fzf_lua = true,
            },
        })
        vim.keymap.set(
            "n",
            "<space>Gg",
            "<cmd>Neogit<cr>",
            { noremap = true, silent = false, desc = "Neogit" }
        )
        vim.keymap.set(
            "v",
            "gG",
            "<cmd>Neogit<cr>",
            { noremap = true, silent = false, desc = "Neogit" }
        )
    end,
}
