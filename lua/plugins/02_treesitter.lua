vim.pack.add { "https://github.com/juniorsundar/nvim-treesitter" }

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
}

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
