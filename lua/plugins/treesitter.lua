return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    branch = "main",
    config = function()
        -- import nvim-treesitter plugin safely
        local status, treesitter = pcall(require, "nvim-treesitter.configs")
        if not status then
            return
        end

        -- configure treesitter
        ---@diagnostic disable-next-line: missing-fields
        treesitter.setup {
            playground = { enable = true },
            -- enable syntax highlighting
            highlight = { enable = true, additional_vim_regex_highlighting = false },
            -- enable indentation
            indent = { enable = true },
            -- ensure these language parsers are installed
            ensure_installed = {
                "c",
                "cpp",
                "python",
                "yaml",
                "markdown",
                "markdown_inline",
                "bash",
                "lua",
                "vim",
                "rust",
                "vimdoc",
                "query",
            },
            ignore_install = { "org" },
            auto_install = false,
        }
    end,
}
