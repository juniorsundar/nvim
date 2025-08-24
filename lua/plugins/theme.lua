return {
  {
    "nvim-tree/nvim-web-devicons",
  },
  {
    "AstroNvim/astrotheme",
    enabled = true,
    priority = 1000,
    event = "VeryLazy",
    lazy = false,
    config = function()
      local c = require "astrotheme.palettes.astrodark"
      require("astrotheme").setup {
        style = {
          transparent = false,
          float = false,
        },
        plugin_default = true,
        highlights = {
          global = {
            ["BlinkCmpMenu"] = { fg = c.ui.text, bg = c.ui.base },
            ["BlinkCmpMenuBorder"] = { fg = c.ui.text, bg = c.ui.base },
            ["Folded"] = { fg = c.ui.text, bg = c.ui.base },
          },
        },
      }
      vim.cmd [[set fillchars+=eob:\ ]]
      vim.cmd.colorscheme "astrodark"
    end,
  },
}
