return {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    config = function()
        require("lspsaga").setup {
            ui = {
                enable = false,
                code_action = "",
            },
            finder = {
                layout = "normal",
            },
        }
    end,
}
