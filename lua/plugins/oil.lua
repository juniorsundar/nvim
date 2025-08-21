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

    vim.keymap.set("n", "<leader>o", "<cmd>Oil<cr>", { desc = "Oil", noremap = false, silent = true })
  end,
}
