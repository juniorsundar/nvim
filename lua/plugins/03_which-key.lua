MiniDeps.now(function()
    MiniDeps.add { source = "folke/which-key.nvim" }

    vim.o.timeout = true
    vim.o.timeoutlen = 500
    require("which-key.colors").Normal = "NormalFloat"

    require("which-key").setup {
        preset = "helix",
        icons = {
            rules = false,
        },
        win = {
            row = -1,
            padding = { 1, 2 },
            title = true,
            title_pos = "center",
            zindex = 1000,
            border = "solid",
        },
        layout = {
            width = { min = 20 },
            spacing = 3,
            align = "center",
        },
        spec = {
            -- { "<leader>l", "<cmd>Lazy<cr>", desc = "Lazy" },
            { "<leader>F", desc = "Find" },
            { "<leader>G", group = "Git" },
            { "<leader><leader>T", group = "Toggle" },
            { "<leader><leader>", group = "LocalLeader" },
        },
    }
end)
