return {
  "stevearc/oil.nvim",
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

    require("which-key").add {
      { "<leader>o", "<cmd>Oil<cr>", desc = "Oil" },
    }
  end,
}
