return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  branch = "master",
  -- branch = "main",
  config = function()
    local status, treesitter = pcall(require, "nvim-treesitter.configs")
    if not status then
      return
    end

    -- configure treesitter
    ---@diagnostic disable-next-line: missing-fields
    treesitter.setup {
      playground = { enable = true },
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true },
      ensure_installed = {
        "c",
        "cpp",
        "python",
        "yaml",
        "markdown",
        "markdown_inline",
        "bash",
        "lua",
        "vim",
        "rust",
        "vimdoc",
        "query",
      },
      ignore_install = { "org" },
      auto_install = false,
    }
  end,
}
