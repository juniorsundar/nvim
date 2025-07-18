return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
    require("which-key.colors").Normal = "NormalFloat"
  end,
  opts = {
    preset = "helix",
    icons = {
      rules = false,
    },
    win = {
      row = -1,
      padding = { 1, 2 },
      title = true,
      title_pos = "center",
      zindex = 1000,
    },
    layout = {
      width = { min = 20 },
      spacing = 3,
      align = "center",
    },
    spec = {
      { "<leader>w", "<cmd>w!<cr>", desc = "Save" },
      { "<leader>q", "<cmd>q<cr>", desc = "Quit" },
      { "<leader>l", "<cmd>Lazy<cr>", desc = "Lazy" },
      { "<leader>m", "<cmd>Mason<cr>", desc = "Mason" },
      { "<leader>o", "<cmd>Oil<cr>", desc = "Oil" },
      { "<leader>F", desc = "Find" },
      { "<leader>G", group = "Git" },
      { "<leader>GD", group = "Diffview" },
      { "<leader><leader>T", group = "Toggle" },
      { "<leader><leader>", group = "LocalLeader" },
    },
  },
}
