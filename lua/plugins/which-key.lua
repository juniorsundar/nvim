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
      spacing = 3, -- spacing between columns
      align = "center", -- align columns left, center or right
    },
    spec = {
      {
        "<leader>w",
        "<cmd>w!<cr>",
        desc = "Save",
      },
      {
        "<leader>q",
        "<cmd>q<cr>",
        desc = "Quit",
      },
      {
        "<leader>l",
        "<cmd>Lazy<cr>",
        desc = "Lazy",
      },
      {
        "<leader>m",
        "<cmd>Mason<cr>",
        desc = "Mason",
      },
      {
        "<leader>o",
        "<cmd>Oil<cr>",
        desc = "Oil",
      },
      {
        "<leader>t",
        "<cmd>lua Snacks.terminal()<cr>",
        desc = "Terminal",
      },
      {
        "<leader>c",
        "<cmd>lua Snacks.bufdelete.delete()<cr>",
        desc = "Close Buffer",
      },
      {
        "<leader>b",
        "<cmd>FzfLua buffers<cr>",
        desc = "Buffers",
      },
      { "<leader>L", group = "LSP" },
      { "<leader>LD", group = "Document" },
      { "<leader>LW", group = "Workspace" },
      {
        "<leader>La",
        "<cmd>FzfLua lsp_code_actions<cr>",
        desc = "Code Action",
      },
      {
        "<leader>Ld",
        "<cmd>lua vim.lsp.buf.definition()<cr>",
        desc = "Definition",
      },
      {
        "<leader>Li",
        "<cmd>lua vim.lsp.buf.implementation()<cr>",
        desc = "Implementation",
      },
      {
        "<leader>Lc",
        "<cmd>lua vim.lsp.buf.declaration()<cr>",
        desc = "Declaration",
      },
      {
        "<leader>Lf",
        "<cmd>lua vim.lsp.buf.format{async=true}<cr>",
        desc = "Format",
      },
      {
        "<leader>Ll",
        "<cmd>lua vim.lsp.codelens.run()<cr>",
        desc = "CodeLens Action",
      },
      {
        "<leader>Ln",
        "<cmd>lua vim.lsp.buf.rename()<cr>",
        desc = "Rename",
      },
      {
        "<leader>Lr",
        "<cmd>FzfLua lsp_references<cr>",
        desc = "References",
      },
      {
        "<leader>Lk",
        "<cmd>lua vim.lsp.buf.hover()<cr>",
        desc = "Hover",
      },
      {
        "<leader>Lt",
        "<cmd>FzfLua lsp_typedefs<cr>",
        desc = "Type Definition",
      },
      {
        "<leader>Lh",
        "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>",
        desc = "Type Hint",
      },
      {
        "<leader>LI",
        "<cmd>LspInfo<cr>",
        desc = "LSP Info",
      },
      {
        "<leader>LDd",
        "<cmd>FzfLua lsp_document_diagnostics<cr>",
        desc = "Document Diagnostics",
      },
      {
        "<leader>LDs",
        "<cmd>FzfLua lsp_document_symbols <cr>",
        desc = "Document Symbols",
      },
      {
        "<leader>LWa",
        "<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>",
        desc = "Add Workspace Folder",
      },
      {
        "<leader>LWd",
        "<cmd>FzfLua lsp_workspace_diagnostics<cr>",
        desc = "Workspace Diagnostics",
      },
      {
        "<leader>LWs",
        "<cmd>FzfLua lsp_workspace_symbols <cr>",
        desc = "Workspace Symbols",
      },
      {
        "<leader>LWr",
        "<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>",
        desc = "Remove Workspace Folder",
      },
      {
        "<leader>LWl",
        "<cmd>lua vim.lsp.buf.list_workspace_folders()<cr>",
        desc = "List Workspace Folders",
      },
      { "<leader>F", desc = "Find" },
      {
        "<leader>Ff",
        "<cmd>FzfLua files<cr>",
        desc = "Files",
      },
      {
        "<leader>Ft",
        "<cmd>FzfLua live_grep<CR>",
        desc = "Text",
      },
      {
        "<leader>Fc",
        "<cmd>FzfLua colorschemes<cr>",
        desc = "Colorscheme",
      },
      {
        "<leader>Fh",
        "<cmd>FzfLua helptags<cr>",
        desc = "Find Help",
      },
      {
        "<leader>Fk",
        "<cmd>FzfLua keymaps<cr>",
        desc = "Keymaps",
      },
      {
        "<leader>Fr",
        "<cmd>FzfLua oldfiles<cr>",
        desc = "Open Recent File",
      },
      {
        "<leader>FM",
        "<cmd>FzfLua manpages<cr>",
        desc = "Man Pages",
      },
      {
        "<leader>FR",
        "<cmd>FzfLua registers<cr>",
        desc = "Registers",
      },
      {
        "<leader>FC",
        "<cmd>FzfLua commands<cr>",
        desc = "Commands",
      },
      {
        "<leader>Fl",
        "<cmd>FzfLua grep_curbuf<cr>",
        desc = "Line",
      },
      { "<leader>G", group = "Git" },
      {
        "<leader>Go",
        "<cmd>FzfLua git_status <cr>",
        desc = "Open changed file",
      },
      {
        "<leader>Gb",
        "<cmd>FzfLua git_branches <cr>",
        desc = "Checkout branch",
      },
      {
        "<leader>Gd",
        "<cmd>Gitsigns diffthis HEAD<cr>",
        desc = "Diff",
      },

      { "<leader>N", group = "Neorg" },
      { "<leader>NJ", group = "Journal" },
      { "<leader>NM", group = "Metadata" },
      { "<leader>NA", group = "Agenda" },
      { "<leader>NF", group = "Find" },
      {
        "<leader>Ni",
        "<cmd>Neorg index<cr>",
        desc = "Index",
      },
      {
        "<leader>NJt",
        "<cmd>Neorg journal today<cr>",
        desc = "Today's Journal",
      },
      {
        "<leader>NJm",
        "<cmd>Neorg journal tomorrow<cr>",
        desc = "Tomorrow's Journal",
      },
      {
        "<leader>NJy",
        "<cmd>Neorg journal yesterday<cr>",
        desc = "Yesterday's Journal",
      },
      {
        "<leader>NMi",
        "<cmd>Neorg inject-metadata<cr>",
        desc = "Inject",
      },
      {
        "<leader>NMu",
        "<cmd>Neorg update-metadata<cr>",
        desc = "Update",
      },

      { "<leader><leader>", group = "LocalLeader" },
    },
  },
}
