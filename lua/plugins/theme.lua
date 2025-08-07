return {
  {
    "nvim-tree/nvim-web-devicons",
  },
  {
    "AstroNvim/astrotheme",
    priority = 1000,
    enabled = true,
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
