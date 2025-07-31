return {
  "mason-org/mason.nvim",
  config = function()
    require("mason").setup()
    require("which-key").add {
      { "<leader>m", "<cmd>Mason<cr>", desc = "Mason" },
    }
  end,
}
