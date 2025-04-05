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
            { "<leader>w",         "<cmd>w!<cr>",                                          desc = "Save" },
            { "<leader>q",         "<cmd>q<cr>",                                           desc = "Quit" },
            { "<leader>l",         "<cmd>Lazy<cr>",                                        desc = "Lazy" },
            { "<leader>m",         "<cmd>Mason<cr>",                                       desc = "Mason" },
            { "<leader>o",         "<cmd>Oil<cr>",                                         desc = "Oil" },
            { "<leader>L",         group = "LSP" },
            { "<leader>LA",        group = "DAP" },
            { "<leader>LD",        group = "Document" },
            { "<leader>LW",        group = "Workspace" },
            { "<leader>La",        "<cmd>lua vim.lsp.buf.code_action()<cr>",               desc = "Code Action" },
            { "<leader>Ld",        "<cmd>lua vim.lsp.buf.definition()<cr>",                desc = "Definition" },
            { "<leader>Li",        "<cmd>lua vim.lsp.buf.implementation()<cr>",            desc = "Implementation" },
            { "<leader>Lc",        "<cmd>lua vim.lsp.buf.declaration()<cr>",               desc = "Declaration" },
            { "<leader>Lf",        "<cmd>lua vim.lsp.buf.format{async=true}<cr>",          desc = "Format" },
            { "<leader>Ll",        "<cmd>lua vim.lsp.codelens.run()<cr>",                  desc = "CodeLens Action" },
            { "<leader>Ln",        "<cmd>lua vim.lsp.buf.rename()<cr>",                    desc = "Rename" },
            { "<leader>Lk",        "<cmd>lua vim.lsp.buf.hover({border = 'rounded'})<cr>", desc = "Hover" },
            { "<leader>LI",        "<cmd>checkhealth lsp<cr>",                             desc = "LSP Info" },
            { "<leader>LWa",       "<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>",      desc = "Add Workspace Folder" },
            { "<leader>LWr",       "<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>",   desc = "Remove Workspace Folder" },
            { "<leader>LWl",       "<cmd>lua vim.lsp.buf.list_workspace_folders()<cr>",    desc = "List Workspace Folders" },
            { "<leader>La",        "<cmd>lua vim.lsp.buf.code_action()<cr>",             desc = "Code Action" },
            { "<leader>Ld",        "<cmd>lua vim.lsp.buf.definition()<cr>",              desc = "Definition" },
            { "<leader>Li",        "<cmd>lua vim.lsp.buf.implementation()<cr>",          desc = "Implementation" },
            { "<leader>Lc",        "<cmd>lua vim.lsp.buf.declaration()<cr>",             desc = "Declaration" },
            { "<leader>Lf",        "<cmd>lua vim.lsp.buf.format{async=true}<cr>",        desc = "Format" },
            { "<leader>Ll",        "<cmd>lua vim.lsp.codelens.run()<cr>",                desc = "CodeLens Action" },
            { "<leader>Ln",        "<cmd>lua vim.lsp.buf.rename()<cr>",                  desc = "Rename" },
            { "<leader>Lk",        "<cmd>lua vim.lsp.buf.hover({border = 'rounded'})<cr>",                   desc = "Hover" },
            { "<leader>LI",        "<cmd>checkhealth lsp<cr>",                           desc = "LSP Info" },
            { "<leader>LWa",       "<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>",    desc = "Add Workspace Folder" },
            { "<leader>LWr",       "<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>", desc = "Remove Workspace Folder" },
            { "<leader>LWl",       "<cmd>lua vim.lsp.buf.list_workspace_folders()<cr>",  desc = "List Workspace Folders" },
            { "<leader>F",         desc = "Find" },
            { "<leader>G",         group = "Git" },
            { "<leader><leader>T", group = "Toggle" },
            { "<leader><leader>",  group = "LocalLeader" },
        },
    },
}
