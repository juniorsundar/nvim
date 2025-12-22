MiniDeps.now(function()
    MiniDeps.add {
        source = "nvim-treesitter/nvim-treesitter",
        checkout = "main",
        hooks = {
            post_checkout = function()
                vim.cmd "TSUpdate"
            end,
        },
    }
    require("nvim-treesitter").setup {
        install_dir = vim.fn.stdpath "data" .. "/site",
    }
    require("nvim-treesitter").install {
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
    }

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

    MiniDeps.add {
        source = "nvim-treesitter/nvim-treesitter-textobjects",
        checkout = "main",
    }
    require("nvim-treesitter-textobjects").setup {
        select = {
            lookahead = true,
            include_surrounding_whitespace = false,
        },

        move = {
            set_jumps = true,
        },
    }

    -- TEXTOBJECTS
    vim.keymap.set({ "x", "o" }, "af", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
    end, { desc = "outer function" })
    vim.keymap.set({ "x", "o" }, "if", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
    end, { desc = "inner function" })
    vim.keymap.set({ "x", "o" }, "ao", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
    end, { desc = "outer class" })
    vim.keymap.set({ "x", "o" }, "io", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
    end, { desc = "inner class" })
    vim.keymap.set({ "x", "o" }, "ad", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@conditional.outer", "textobjects")
    end, { desc = "outer conditional" })
    vim.keymap.set({ "x", "o" }, "id", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@conditional.inner", "textobjects")
    end, { desc = "inner conditional" })
    vim.keymap.set({ "x", "o" }, "aw", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@loop.outer", "textobjects")
    end, { desc = "outer loop" })
    vim.keymap.set({ "x", "o" }, "iw", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@loop.inner", "textobjects")
    end, { desc = "inner loop" })
    vim.keymap.set({ "x", "o" }, "as", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
    end)

    -- FUNCTION
    vim.keymap.set({ "n", "x", "o" }, "]f", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
    end, { desc = "Next function [start]" })
    vim.keymap.set({ "n", "x", "o" }, "]F", function()
        require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
    end, { desc = "Next function [end]" })
    vim.keymap.set({ "n", "x", "o" }, "[f", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
    end, { desc = "Previous function [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[F", function()
        require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
    end, { desc = "Previous function [end]" })

    -- CLASS
    vim.keymap.set({ "n", "x", "o" }, "]o", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
    end, { desc = "Next class [start]" })
    vim.keymap.set({ "n", "x", "o" }, "]O", function()
        require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects")
    end, { desc = "Next class [end]" })
    vim.keymap.set({ "n", "x", "o" }, "[o", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
    end, { desc = "Previous class [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[O", function()
        require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects")
    end, { desc = "Previous class [end]" })

    -- SCOPE
    vim.keymap.set({ "n", "x", "o" }, "]s", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@local.scope", "locals")
    end, { desc = "Next scope [start]" })
    vim.keymap.set({ "n", "x", "o" }, "]S", function()
        require("nvim-treesitter-textobjects.move").goto_next_end("@local.scope", "locals")
    end, { desc = "Next scope [end]" })
    vim.keymap.set({ "n", "x", "o" }, "[s", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@local.scope", "locals")
    end, { desc = "Previous scope [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[S", function()
        require("nvim-treesitter-textobjects.move").goto_previous_end("@local.scope", "locals")
    end, { desc = "Previous scope [end]" })

    -- LOOP
    vim.keymap.set({ "n", "x", "o" }, "]w", function()
        require("nvim-treesitter-textobjects.move").goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
    end, { desc = "Next loop [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[w", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start({ "@loop.inner", "@loop.outer" }, "textobjects")
    end, { desc = "Previous loop [start]" })

    -- FOLD
    vim.keymap.set({ "n", "x", "o" }, "]z", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@fold", "folds")
    end, { desc = "Next fold [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[z", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@fold", "folds")
    end, { desc = "Previous fold [start]" })

    -- CONDITIONAL
    vim.keymap.set({ "n", "x", "o" }, "]d", function()
        require("nvim-treesitter-textobjects.move").goto_next("@conditional.outer", "textobjects")
    end, { desc = "Next conditional" })
    vim.keymap.set({ "n", "x", "o" }, "[d", function()
        require("nvim-treesitter-textobjects.move").goto_previous("@conditional.outer", "textobjects")
    end, { desc = "Previous conditional" })

    local ts_repeat_move = require "nvim-treesitter-textobjects.repeatable_move"

    -- Repeat movement with ; and ,
    vim.keymap.set({ "n", "x", "o" }, "<end>", ts_repeat_move.repeat_last_move_next)
    vim.keymap.set({ "n", "x", "o" }, "<home>", ts_repeat_move.repeat_last_move_previous)
end)
