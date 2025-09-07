return {
    "kylechui/nvim-surround",
    enabled = true,
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup()
    end,
}
