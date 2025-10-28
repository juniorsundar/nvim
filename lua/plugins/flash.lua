local M = {
    source = "folke/flash.nvim",
    config = function()
        require("flash").setup()
        vim.keymap.set(
            { "n", "x", "o" },
            "<C-s>",
            function()
                require("flash").jump()
            end,
            { desc = "Flash", noremap = false, silent = true }
        )
        vim.keymap.set(
            { "n", "x", "o" },
            "<C-M-s>",
            function()
                require("flash").treesitter()
            end,
            { desc = "Flash Treesitter", noremap = false, silent = true }
        )
        vim.keymap.set(
            "o",
            "gr",
            function()
                require("flash").remote()
            end,
            { desc = "Remote Flash", noremap = false, silent = true }
        )
        vim.keymap.set(
            { "o", "x" },
            "gR",
            function()
                require("flash").treesitter_search()
            end,
            { desc = "Treesitter Search", noremap = false, silent = true }
        )
        vim.keymap.set(
            { "n", "x", "o" },
            "<c-space>",
            function()
                require("flash").treesitter({
                    actions = {
                        ["<c-space>"] = "next",
                        ["<BS>"] = "prev"
                    }
                })
            end,
            { desc = "Treesitter incremental selection", noremap = false, silent = true }
        )
    end
}

return M
