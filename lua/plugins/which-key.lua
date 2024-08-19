return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 500
        require("which-key.colors").Normal = "NormalFloat"
    end,
    opts = {
        preset = "modern",
        icons = {
            rules = false,
        },
        win = {
            row = -1,
            -- border = "rounded",
            padding = { 1, 2 }, -- extra window padding [top/bottom, right/left]
            title = true,
            title_pos = "center",
            zindex = 1000,
            -- Additional vim.wo and vim.bo options
            bo = {},
            wo = {
                -- winblend = 10, -- value between 0-100 0 for fully opaque and 100 for fully transparent
            },
        },
        layout = {
            width = { min = 20 }, -- min and max width of the columns
            spacing = 3,          -- spacing between columns
            align = "center",     -- align columns left, center or right
        },
        spec = {
            -- { "<leader>a",   "<cmd>Dashboard<cr>",                                                              desc = "Dashboard" },
            { "<leader>a",         "<cmd>Alpha<cr>",                                                              desc = "Alpha" },
            { "<leader>w",         "<cmd>w!<cr>",                                                                 desc = "Save" },
            { "<leader>q",         "<cmd>q<cr>",                                                                  desc = "Quit" },
            { "<leader>l",         "<cmd>Lazy<cr>",                                                               desc = "Lazy" },
            { "<leader>m",         "<cmd>Mason<cr>",                                                              desc = "Mason" },
            { "<leader>o",         "<cmd>Oil<cr>",                                                                desc = "Oil" },
            { "<leader>t",         "<cmd>terminal<cr>",                                                           desc = "Terminal" },
            { "<leader>u",         "<cmd>UndotreeToggle<cr>",                                                     desc = "Undotree" },
            { "<leader>c",         "<cmd>bdelete<cr>",                                                            desc = "Close Buffer" },
            -- { "<leader>b",         "<cmd>FzfLua buffers<cr>",                                                     desc = "Buffers" },
            { "<leader>b",         "<cmd>Telescope buffers <cr>",                                                 desc = "Buffers" },
            { "<leader>/",         "<cmd>GrugFar<cr>",                                                            desc = "Grepper" },

            { "<leader>L",         group = "LSP" },
            { "<leader>LD",        group = "Document" },
            { "<leader>LW",        group = "Workspace" },
            { "<leader>La",        "<cmd>Lspsaga code_action<cr>",                                                desc = "Code Action" },
            { "<leader>Lf",        "<cmd>lua vim.lsp.buf.format{async=true}<cr>",                                 desc = "Format" },
            { "<leader>Ll",        "<cmd>lua vim.lsp.codelens.run()<cr>",                                         desc = "CodeLens Action" },
            { "<leader>Ln",        "<cmd>Lspsaga rename<cr>",                                                     desc = "Rename" },
            { "<leader>Ld",        "<cmd>Lspsaga peek_definition<cr>",                                            desc = "Definition (Peek)" },
            { "<leader>Lr",        "<cmd>Lspsaga finder ref ++normal<cr>",                                        desc = "References" },
            { "<leader>Lk",        "<cmd>Lspsaga hover_doc<cr>",                                                  desc = "Hover" },
            { "<leader>Lt",        "<cmd>Lspsaga finder tyd ++normal<cr>",                                        desc = "Type Definition" },
            { "<leader>Lh",        "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>", desc = "Type Hint" },
            { "<leader>Lo",        "<cmd>Lspsaga outline<cr>",                                                    desc = "Outline" },
            { "<leader>LI",        "<cmd>LspInfo<cr>",                                                            desc = "LSP Info" },
            { "<leader>LDd",       "<cmd>Lspsaga show_buf_diagnostics ++normal<cr>",                              desc = "Document Diagnostics" },
            { "<leader>LDs",       "<cmd>Telescope lsp_document_symbols <cr>",                                    desc = "Document Symbols" },
            { "<leader>LDj",       "<cmd>Lspsaga diagnostic_jump_next<CR>",                                       desc = "Next Diagnostic" },
            { "<leader>LWa",       "<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>",                             desc = "Add Workspace Folder" },
            { "<leader>LWd",       "<cmd>Lspsaga show_workspace_diagnostics ++normal<cr>",                        desc = "Workspace Diagnostics" },
            { "<leader>LWs",       "<cmd>Telescope lsp_workspace_symbols <cr>",                                   desc = "Workspace Symbols" },
            { "<leader>LWr",       "<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>",                          desc = "Remove Workspace Folder" },
            { "<leader>LWl",       "<cmd>lua vim.lsp.buf.list_workspace_folders()<cr>",                           desc = "List Workspace Folders" },

            { "<leader>F",         desc = "Find", },
            { "<leader>Ff",        "<cmd>Telescope find_files<cr>",                                               desc = "Files" },
            { "<leader>Ft",        "<cmd>Telescope live_grep <CR>",                                               desc = "Text" },
            { "<leader>Fc",        "<cmd>Telescope colorscheme <cr>",                                             desc = "Colorscheme" },
            { "<leader>Fh",        "<cmd>Telescope help_tags <cr>",                                               desc = "Find Help" },
            { "<leader>Fk",        "<cmd>Telescope keymaps <cr>",                                                 desc = "Keymaps" },
            { "<leader>Fr",        "<cmd>Telescope oldfiles <cr>",                                                desc = "Open Recent File" },
            { "<leader>FM",        "<cmd>Telescope man_pages <cr>",                                               desc = "Man Pages" },
            { "<leader>FR",        "<cmd>Telescope registers <cr>",                                               desc = "Registers" },
            { "<leader>FC",        "<cmd>Telescope commands <cr>",                                                desc = "Commands" },


            { "<leader>A",         group = "Autocompletion", },
            { "<leader>Ae",        "<cmd>lua require 'cmp'.setup{ enabled = true }<cr>",                          desc = "Enabled" },
            { "<leader>Ad",        "<cmd>lua require 'cmp'.setup{ enabled  false }<cr>",                          desc = "Disabled" },

            { "<leader>G",         group = "Git", },
            { "<leader>Go",        "<cmd>Telescope git_status <cr>",                                              desc = "Open changed file" },
            { "<leader>Gb",        "<cmd>Telescope git_branches <cr>",                                            desc = "Checkout branch" },
            { "<leader>Gd",        "<cmd>Gitsigns diffthis HEAD<cr>",                                             desc = "Diff" },

            { "<leader>N",         group = "Neorg", },
            { "<leader>NJ",        group = "Journal", },
            { "<leader>NM",        group = "Metadata", },
            { "<leader>NF",        group = "Find", },
            { "<leader>Ni",        "<cmd>Neorg index<cr>",                                                        desc = "Index" },
            { "<leader>NJt",       "<cmd>Neorg journal today<cr>",                                                desc = "Today's Journal" },
            { "<leader>NJm",       "<cmd>Neorg journal tomorrow<cr>",                                             desc = "Tomorrow's Journal" },
            { "<leader>NJy",       "<cmd>Neorg journal yesterday<cr>",                                            desc = "Yesterday's Journal" },
            { "<leader>NMi",       "<cmd>Neorg inject-metadata<cr>",                                              desc = "Inject" },
            { "<leader>NMu",       "<cmd>Neorg update-metadata<cr>",                                              desc = "Update" },

            { "<leader><leader>",  group = "LocalLeader", },
            { "<leader><leader>r", group = "org-roam", },
            { "<leader><leader>o", group = "org-mode", },
        },
    },
}
