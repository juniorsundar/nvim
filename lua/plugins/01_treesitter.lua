MiniDeps.now(function()
    MiniDeps.add({
        source = "nvim-treesitter/nvim-treesitter",
        checkout = "main",
        hooks = {
            post_checkout = function()
                vim.cmd("TSUpdate")
            end,
        },
    })
    require 'nvim-treesitter'.setup {
        install_dir = vim.fn.stdpath('data') .. '/site'
    }
    require("nvim-treesitter").install({
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
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = {
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
        },
        callback = function()
            vim.treesitter.start()
            vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end,
    })
end)
