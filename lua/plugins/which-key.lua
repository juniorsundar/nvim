return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 500
        require("which-key.colors").Normal = "NormalFloat"
    end,
    opts = {
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
        },
        layout = {
            width = { min = 20 },
            spacing = 3,
            align = "center",
        },
        spec = {
            { "<leader>w",         "<cmd>w!<cr>",                                            desc = "Save" },
            { "<leader>q",         "<cmd>q<cr>",                                             desc = "Quit" },
            { "<leader>l",         "<cmd>Lazy<cr>",                                          desc = "Lazy" },
            { "<leader>m",         "<cmd>Mason<cr>",                                         desc = "Mason" },
            { "<leader>o",         "<cmd>Oil<cr>",                                           desc = "Oil" },
            { "<leader>L",         group = "LSP" },
            { "<leader>LA",        group = "DAP" },
            { "<leader>LD",        group = "Document" },
            { "<leader>LW",        group = "Workspace" },
            { "<leader>LI",        "<cmd>checkhealth lsp<cr>",                                        desc = "LSP Info" },
            { "<leader>La",        function() vim.lsp.buf.code_action() end,                 desc = "Code Action" },
            { "<leader>Ld",        function() vim.lsp.buf.definition() end,                  desc = "Definition" },
            { "<leader>Li",        function() vim.lsp.buf.implementation() end,              desc = "Implementation" },
            { "<leader>Lc",        function() vim.lsp.buf.declaration() end,                 desc = "Declaration" },
            { "<leader>Lf",        function() vim.lsp.buf.format { async = true } end,       desc = "Format" },
            { "<leader>Ll",        function() vim.lsp.codelens.run() end,                    desc = "CodeLens Action" },
            { "<leader>Ln",        function() vim.lsp.buf.rename() end,                      desc = "Rename" },
            { "<leader>Lk",        function() vim.lsp.buf.hover({ border = 'rounded' }) end, desc = "Hover" },
            { "<leader>LWa",       function() vim.lsp.buf.add_workspace_folder() end,        desc = "Add Workspace Folder" },
            { "<leader>LWr",       function() vim.lsp.buf.remove_workspace_folder() end,     desc = "Remove Workspace Folder" },
            { "<leader>LWl",       function() vim.lsp.buf.list_workspace_folders() end,      desc = "List Workspace Folders" },
            { "<leader>F",         desc = "Find" },
            { "<leader>G",         group = "Git" },
            { "<leader>GD",        group = "Diffview" },
            { "<leader><leader>T", group = "Toggle" },
            { "<leader><leader>",  group = "LocalLeader" },
        },
    },
}
