vim.pack.add { "https://github.com/nvim-treesitter/nvim-treesitter" }

local install_dir = vim.env.OUTPOST_SESSION == "1" and vim.fs.joinpath(vim.env.HOME, ".cache/outpost/treesitter")
    or vim.fn.stdpath "data" .. "/site"

require("nvim-treesitter").setup {
    install_dir = install_dir,
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
    "asciidoc",
    "asciidoc_inline",
}

vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = function()
        local parsers = require "nvim-treesitter.parsers"
        parsers.asciidoc = {
            install_info = {
                url = "https://github.com/cathaysia/tree-sitter-asciidoc",
                branch = "master",
                location = "tree-sitter-asciidoc",
                queries = "tree-sitter-asciidoc/queries",
            },
        }
        parsers.asciidoc_inline = {
            install_info = {
                url = "https://github.com/cathaysia/tree-sitter-asciidoc",
                branch = "master",
                location = "tree-sitter-asciidoc_inline",
                queries = "tree-sitter-asciidoc_inline/queries",
            },
        }
    end,
})

local toolchain = { "tree-sitter", "cc", "curl", "tar" }

if vim.iter(toolchain):all(function(tool)
    return vim.fn.executable(tool) == 1
end) then
    require("nvim-treesitter").install(languages)
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = languages,
    callback = function()
        if not pcall(vim.treesitter.start) then
            return
        end

        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
})

vim.treesitter.language.register("asciidoc", { "asciidoc" })
