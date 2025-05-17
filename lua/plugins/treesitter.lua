return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
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
            -- auto install above language parsers
            auto_install = false,
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "gnn", -- set to `false` to disable one of the mappings
                    node_incremental = "grM",
                    scope_incremental = "grS",
                    node_decremental = "grN",
                },
            },
        }
    end,
}
