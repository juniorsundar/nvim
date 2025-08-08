return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you use the mini.nvim suite
  ft = "markdown",
  ----@module 'render-markdown'
  ----@type render.md.UserConfig
  -- opts = {},
  config = function()
    require("render-markdown").setup {
      completions = {
        -- lsp = { enabled = true },
        blink = { enabled = true },
      },
      render_modes = true,
      checkbox = {
        custom = {
          cancelled = {raw = '[-]', rendered = '', highlight = 'RenderMarkdownDash', scope_highlight = 'RenderMarkdownDash'},
          doing = {raw = '[/]', rendered = '󰥔', highlight = 'RenderMarkdownTodo', scope_highlight = nil},
        }
      }
    }
  end,
}
