require("micro.pack").add "gh:nvim-treesitter/nvim-treesitter"
require("nvim-treesitter").setup {
    install_dir = vim.fn.stdpath "data" .. "/site",
}
local languages = {
    "bash",
    "c",
    "c3",
    "cpp",
    "d",
    "go",
    "gomod",
    "javascript",
    "json",
    "lua",
    "markdown",
    "nix",
    "odin",
    "python",
    "rust",
    "toml",
    "yaml",
    "zig",
    "html",
    "latex",
    "regex",
    "v",
    "gleam",
}

require("nvim-treesitter").install(languages)

vim.api.nvim_create_autocmd("FileType", {
    pattern = languages,
    callback = function()
        vim.treesitter.start()
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
})
