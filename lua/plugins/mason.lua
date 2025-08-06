return {
  "mason-org/mason.nvim",
  config = function()
    require("mason").setup()
    vim.keymap.set("n", "<leader>m", "<cmd>Mason<cr>", { desc = "Mason", noremap = false, silent = true })
  end,
}
