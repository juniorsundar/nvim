return {
    "ibhagwan/fzf-lua",
    enabled = false,
    keys = {
        { "<leader>b",   "<cmd>FzfLua buffers<cr>",                   desc = "Buffers" },
        { "<leader>Ff",  "<cmd>FzfLua files<cr>",                     desc = "Files" },
        { "<leader>Ft",  "<cmd>FzfLua live_grep<CR>",                 desc = "Text" },
        { "<leader>Fc",  "<cmd>FzfLua colorschemes<cr>",              desc = "Colorscheme" },
        { "<leader>Fh",  "<cmd>FzfLua helptags<cr>",                  desc = "Find Help" },
        { "<leader>Fk",  "<cmd>FzfLua keymaps<cr>",                   desc = "Keymaps" },
        { "<leader>Fr",  "<cmd>FzfLua oldfiles<cr>",                  desc = "Open Recent File" },
        { "<leader>FM",  "<cmd>FzfLua manpages<cr>",                  desc = "Man Pages" },
        { "<leader>FR",  "<cmd>FzfLua registers<cr>",                 desc = "Registers" },
        { "<leader>FC",  "<cmd>FzfLua commands<cr>",                  desc = "Commands" },
        { "<leader>Fl",  "<cmd>FzfLua grep_curbuf<cr>",               desc = "Line" },
        { "<leader>Go",  "<cmd>FzfLua git_status <cr>",               desc = "Open changed file" },
        { "<leader>Gb",  "<cmd>FzfLua git_branches <cr>",             desc = "Checkout branch" },
        { "<leader>Lr",  "<cmd>FzfLua lsp_references<cr>",            desc = "References" },
        { "<leader>Lt",  "<cmd>FzfLua lsp_typedefs<cr>",              desc = "Type Definition" },
        { "<leader>LDd", "<cmd>FzfLua lsp_document_diagnostics<cr>",  desc = "Document Diagnostics" },
        { "<leader>LDs", "<cmd>FzfLua lsp_document_symbols <cr>",     desc = "Document Symbols" },
        { "<leader>LWd", "<cmd>FzfLua lsp_workspace_diagnostics<cr>", desc = "Workspace Diagnostics" },
        { "<leader>LWs", "<cmd>FzfLua lsp_workspace_symbols <cr>",    desc = "Workspace Symbols" },
    },
    config = function()
        -- calling `setup` is optional for customization
        local actions = require "fzf-lua.actions"
        require("fzf-lua").setup {
            winopts = {
                split = "belowright new",
                preview = {
                    horizontal = "right:50%",
                    delay = 50,
                },
            },
        }
    end,
}
