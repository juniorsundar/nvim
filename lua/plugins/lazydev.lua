local M = {
    source = "folke/lazydev.nvim",
    config = function()
        require("lazydev").setup({
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                { "nvim-dap-ui" },
                { path = "snacks.nvim",        words = { "Snacks" } },
                { path = "lazy.nvim",          words = { "LazyVim" } },
                { path = "wezterm-types",      mods = { "wezterm" } },
            },
        })
    end,
}

return M
