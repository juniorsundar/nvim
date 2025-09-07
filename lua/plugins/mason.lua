return {
    "mason-org/mason.nvim",
    lazy = true,
    config = function()
        require("mason").setup()
    end,
}
