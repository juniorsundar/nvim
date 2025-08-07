return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    enabled = false,
    config = function()
      local cyberdream = {
        base = "#16181a",
        blue = "#5ea1ff",
        crust = "#3c4048",
        flamingo = "#ff9f9f",
        green = "#5eff6c",
        lavender = "#ff5ef1",
        mantle = "#1e2124",
        maroon = "#d96666",
        mauve = "#bd5eff",
        overlay0 = "#474a55",
        overlay1 = "#5a5e6b",
        overlay2 = "#6e7280",
        peach = "#ffbd5e",
        pink = "#ff5ea0",
        red = "#ff6e5e",
        rosewater = "#ffd1dc",
        sapphire = "#4a90e2",
        sky = "#5ef1ff",
        subtext0 = "#8a8e99",
        subtext1 = "#a0a4b8",
        surface0 = "#26282e",
        surface1 = "#2e3138",
        surface2 = "#363940",
        teal = "#64d8cb",
        text = "#ffffff",
        yellow = "#f1ff5e",
      }
      local config = {
        color_overrides = {
          macchiato = cyberdream,
        },
        custom_highlights = function(colors)
          return {}
        end,
        highlight_overrides = {
          macchiato = function(colors)
            return {
              NormalFloat = { fg = colors.text, bg = colors.base },
              Comment = { fg = colors.overlay1 },
              LineNr = { fg = colors.overlay1 },
              CursorLineNr = { fg = colors.text },
              WhichKey = { fg = colors.text, bg = colors.base },
              WhichKeyNormal = { fg = colors.text, bg = colors.base },
              Folded = { fg = colors.crust, bg = colors.none },
            }
          end,
        },
        transparent_background = false,
        auto_integrations = true,
      }
      require("catppuccin").setup(config)
      vim.cmd.colorscheme "catppuccin-macchiato"
    end,
  },
  {
    "Mofiqul/vscode.nvim",
    enabled = false,
    config = function()
      vim.cmd.colorscheme "vscode"
    end,
  },
  {
    "folke/tokyonight.nvim",
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup {
        style = "storm",
        transparent = true,
        lualine_bold = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      }
      vim.cmd.colorscheme "tokyonight"
    end,
  },
  {
    "NTBBloodbath/doom-one.nvim",
    enabled = false,
    config = function()
      vim.g.doom_one_cursor_coloring = false
      vim.g.doom_one_terminal_colors = true
      vim.g.doom_one_italic_comments = true
      vim.g.doom_one_enable_treesitter = true
      vim.g.doom_one_diagnostics_text_color = false
      vim.g.doom_one_transparent_background = false

      vim.g.doom_one_pumblend_enable = true
      vim.g.doom_one_pumblend_transparency = 20
      vim.cmd [[set fillchars+=eob:\ ]]
      vim.cmd.colorscheme "doom-one"
    end,
  },
  {
    "vague2k/vague.nvim",
    enabled = false,
    priority = 1000,
    config = function()
      require("vague").setup {}
    end,
  },
  {
    "dgox16/oldworld.nvim",
    lazy = false,
    enabled = false,
    priority = 1000,
    config = function()
      require("oldworld").setup {
        terminal_colors = true,
        variant = "default",
        styles = {
          comments = {},
          keywords = {},
          identifiers = {},
          functions = {},
          variables = {},
          booleans = {},
        },
        integrations = {
          alpha = true,
          cmp = true,
          flash = true,
          gitsigns = true,
          hop = false,
          indent_blankline = true,
          lazy = true,
          lsp = true,
          markdown = true,
          mason = true,
          navic = false,
          neo_tree = false,
          neogit = false,
          neorg = false,
          noice = true,
          notify = true,
          rainbow_delimiters = true,
          telescope = true,
          treesitter = true,
        },
        highlight_overrides = {},
      }
      vim.cmd.colorscheme "oldworld"
    end,
  },
}
