return {
  {
    "nvim-mini/mini.pairs",
    enabled = false,
    event = "VeryLazy",
    config = function()
      require("mini.pairs").setup {
        modes = { insert = true, command = true, terminal = false },
        -- skip autopair when next character is one of these
        skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
        -- skip autopair when the cursor is inside these treesitter nodes
        skip_ts = { "string" },
        -- skip autopair when next character is closing pair
        -- and there are more closing pairs than opening pairs
        skip_unbalanced = true,
        -- better deal with markdown code blocks
        markdown = true,
      }
    end,
  },
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    config = function()
      local ai = require "mini.ai"
      ai.setup {
        n_lines = 500,
      }
    end,
  },
  {
    "nvim-mini/mini.move",
    event = "VeryLazy",
    config = function()
      require("mini.move").setup {
        mappings = {
          left = "<S-left>",
          right = "<S-right>",
          down = "<S-down>",
          up = "<S-up>",

          line_left = "<S-left>",
          line_right = "<S-right>",
          line_down = "<S-down>",
          line_up = "<S-up>",
        },
      }
    end,
  },
  {
    "nvim-mini/mini.statusline",
    enabled = false,
    event = "VeryLazy",
    config = function()
      require("mini.statusline").setup {}
    end,
  },
  {
    "nvim-mini/mini.surround",
    enabled = false,
    event = "VeryLazy",
    config = function()
      require("mini.surround").setup()
    end,
  },
}
