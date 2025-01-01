return {
  {
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

        { "<leader><leader>", group = "LocalLeader" },
      },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
        -- stylua: ignore
        keys = {
            { "<c-s>",   mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
            { "<c-S-S>", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
            { "r",       mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
            { "R",       mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
        },
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },
  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    config = function()
      require("mini.pairs").setup()
    end,
  },
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup()
    end,
  },
  {
    "echasnovski/mini.move",
    event = "VeryLazy",
    config = function()
      require("mini.move").setup()
    end,
  },
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup {
        columns = {
          "size",
          "icon",
        },
        view_options = {
          show_hidden = true,
        },
      }
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    dependencies = {
      "sindrets/diffview.nvim",
      {
        "NeogitOrg/neogit",
        dependencies = {
          "nvim-lua/plenary.nvim", -- required
        },
        keys = {
          {
            "<leader>Gg",
            "<cmd>Neogit<cr>",
            desc = "Lazygit",
          },
        },
        config = function()
          require("neogit").setup {
            signs = {
              -- { CLOSED, OPENED }
              hunk = { "", "" },
              item = { "", "" },
              section = { "", "" },
            },
            graph_style = "kitty",
          }
        end,
      },
    },
    config = function()
      require("gitsigns").setup {
        signs = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "-" }, -- '_'
          topdelete = { text = "" }, -- '‾'
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
        numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir = {
          follow_files = true,
        },
        attach_to_untracked = true,
        current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
          delay = 1000,
          ignore_whitespace = false,
          virt_text_priority = 100,
        },
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil, -- Use default
        max_file_length = 40000, -- Disable if file is longer than this (in lines)
        preview_config = {
          -- Options passed to nvim_open_win
          border = "single",
          style = "minimal",
          relative = "cursor",
          row = 0,
          col = 1,
        },
      }

      vim.keymap.set(
        "n",
        "<space>G]",
        "<cmd>lua require('gitsigns').next_hunk()<cr>",
        { noremap = true, silent = false, desc = "Next Hunk" }
      )
      vim.keymap.set(
        "n",
        "<space>G[",
        "<cmd>lua require('gitsigns').prev_hunk()<cr>",
        { noremap = true, silent = false, desc = "Previous Hunk" }
      )
      vim.keymap.set(
        "n",
        "<space>Gp",
        "<cmd>lua require('gitsigns').preview_hunk()<cr>",
        { noremap = true, silent = false, desc = "Preview Hunk" }
      )
      vim.keymap.set(
        "n",
        "<space>Gr",
        "<cmd>lua require('gitsigns').reset_hunk()<cr>",
        { noremap = true, silent = false, desc = "Reset Hunk" }
      )
      vim.keymap.set(
        "n",
        "<space>Gs",
        "<cmd>lua require('gitsigns').stage_hunk()<cr>",
        { noremap = true, silent = false, desc = "Stage Hunk" }
      )
      vim.keymap.set(
        "n",
        "<space>Gu",
        "<cmd>lua require('gitsigns').undo_stage_hunk()<cr>",
        { noremap = true, silent = false, desc = "Undo Stage Hunk" }
      )
      vim.keymap.set(
        "n",
        "<space>GR",
        "<cmd>lua require('gitsigns').reset_buffer()<cr>",
        { noremap = true, silent = false, desc = "Reset Buffer" }
      )
      vim.keymap.set(
        "n",
        "<space>GB",
        "<cmd>lua require('gitsigns').blame()<cr>",
        { noremap = true, silent = false, desc = "Blame" }
      )
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local lualine = require "lualine"

            -- Color table for highlights
            -- stylua: ignore
            local cyberdream = {
                bg       = '#1e2124',
                blue     = '#5ea1ff',
                cyan     = '#64d8cb',
                darkblue = '#081633',
                fg       = '#ffffff',
                green    = '#5eff6c',
                magenta  = '#ff5ef1',
                orange   = '#ffbd5e',
                red      = '#ff6e5e',
                violet   = '#bd5eff',
                yellow   = '#f1ff5e',
            }

      local colors = cyberdream

      local conditions = {
        buffer_not_empty = function()
          return vim.fn.empty(vim.fn.expand "%:t") ~= 1
        end,
        hide_in_width = function()
          return vim.fn.winwidth(0) > 80
        end,
        check_git_workspace = function()
          local filepath = vim.fn.expand "%:p:h"
          local gitdir = vim.fn.finddir(".git", filepath .. ";")
          return gitdir and #gitdir > 0 and #gitdir < #filepath
        end,
      }

      -- Config
      local config = {
        options = {
          disabled_filetypes = {
            "NeogitStatus",
            "snacks_dashboard",
            "oil",
            "ministarter",
            "fzf",
          },
          -- Disable sections and component separators
          component_separators = "",
          section_separators = "",
          theme = {
            -- We are going to use lualine_c an lualine_x as left and
            -- right section. Both are highlighted by c theme .  So we
            -- are just setting default looks o statusline
            normal = { c = { fg = colors.fg, bg = colors.bg } },
            inactive = { c = { fg = colors.fg, bg = colors.bg } },
          },
        },
        sections = {
          -- these are to remove the defaults
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          -- These will be filled later
          lualine_c = {},
          lualine_x = {},
        },
        inactive_sections = {
          -- these are to remove the defaults
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
        },
      }

      -- Inserts a component in lualine_c at left section
      local function ins_left(component)
        table.insert(config.sections.lualine_c, component)
      end

      -- Inserts a component in lualine_x at right section
      local function ins_right(component)
        table.insert(config.sections.lualine_x, component)
      end

      ins_left {
        function()
          return ""
        end,
        color = function()
          -- auto change color according to neovims mode
          local mode_color = {
            n = colors.blue,
            i = colors.red,
            v = colors.green,
            [""] = colors.green,
            V = colors.green,
            c = colors.magenta,
            no = colors.red,
            s = colors.orange,
            S = colors.orange,
            [""] = colors.orange,
            ic = colors.yellow,
            R = colors.violet,
            Rv = colors.violet,
            cv = colors.red,
            ce = colors.red,
            r = colors.cyan,
            rm = colors.cyan,
            ["r?"] = colors.cyan,
            ["!"] = colors.red,
            t = colors.red,
          }
          return { bg = mode_color[vim.fn.mode()] }
        end,
        padding = { left = 0, right = 1 }, -- We don't need space before this
      }

      ins_left {
        "mode",
        color = function()
          -- auto change color according to neovims mode
          local mode_color = {
            n = colors.blue,
            i = colors.red,
            v = colors.green,
            [""] = colors.green,
            V = colors.green,
            c = colors.magenta,
            no = colors.red,
            s = colors.orange,
            S = colors.orange,
            [""] = colors.orange,
            ic = colors.yellow,
            R = colors.violet,
            Rv = colors.violet,
            cv = colors.red,
            ce = colors.red,
            r = colors.cyan,
            rm = colors.cyan,
            ["r?"] = colors.cyan,
            ["!"] = colors.red,
            t = colors.red,
          }
          return { bg = mode_color[vim.fn.mode()], fg = colors.bg }
        end,
        padding = { left = 1, right = 1 },
      }

      ins_left {
        "branch",
        icon = "",
        color = { fg = colors.violet, gui = "bold" },
        padding = { left = 1, right = 1 },
      }

      ins_left {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        symbols = { error = " ", warn = " ", info = " " },
        diagnostics_color = {
          error = { fg = colors.red },
          warn = { fg = colors.yellow },
          info = { fg = colors.cyan },
        },
      }

      ins_left {
        "filename",
        cond = conditions.buffer_not_empty,
        color = { fg = colors.fg, gui = "bold" },
      }

      -- Insert mid section. You can make any number of sections in neovim :)
      -- for lualine it's any number greater then 2
      ins_left {
        function()
          return "%="
        end,
      }

      -- Add components to right sections
      ins_right {
        "filetype",
        icons_enabled = true, -- I think icons are cool but Eviline doesn't have them. sigh
        color = { gui = "italic" },
      }

      ins_right { "location" }

      ins_right { "progress", color = { fg = colors.fg, gui = "bold" } }

      ins_right {
        function()
          return "▊"
        end,
        color = function()
          -- auto change color according to neovims mode
          local mode_color = {
            n = colors.blue,
            i = colors.red,
            v = colors.green,
            [""] = colors.green,
            V = colors.green,
            c = colors.magenta,
            no = colors.red,
            s = colors.orange,
            S = colors.orange,
            [""] = colors.orange,
            ic = colors.yellow,
            R = colors.violet,
            Rv = colors.violet,
            cv = colors.red,
            ce = colors.red,
            r = colors.cyan,
            rm = colors.cyan,
            ["r?"] = colors.cyan,
            ["!"] = colors.red,
            t = colors.red,
          }
          return { fg = mode_color[vim.fn.mode()] }
        end,
        padding = { left = 1 },
      }

      -- Now don't forget to initialize lualine
      lualine.setup(config)
    end,
  },
  {
    "OXY2DEV/markview.nvim",
    -- lazy = false,
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("markview").setup {
        list_items = {
          indent_size = 2,
          shift_width = 2,
        },
      }
    end,
  },
}
