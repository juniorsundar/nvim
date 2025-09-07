return {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
        library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            { "nvim-dap-ui" },
            { path = "snacks.nvim", words = { "Snacks" } },
            { path = "lazy.nvim", words = { "LazyVim" } },
            { path = "wezterm-types", mods = { "wezterm" } },
        },
    },
}
