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

    MiniDeps.add({ source = "nvim-treesitter/nvim-treesitter-context" })
    require 'treesitter-context'.setup {
        enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
        multiwindow = false,      -- Enable multiwindow support.
        max_lines = 0,            -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to show for a single context
        trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'topline',          -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex = 20,     -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
    }
    vim.cmd [[hi TreesitterContextBottom gui=underline guisp=Grey]]
    vim.cmd [[hi TreesitterContextLineNumberBottom gui=underline guisp=Grey]]

    MiniDeps.add({
        source = "nvim-treesitter/nvim-treesitter-textobjects",
        checkout = "main",
    })
    require("nvim-treesitter-textobjects").setup {
        move = {
            set_jumps = true,
        },
    }

    -- FUNCTION
    vim.keymap.set({ "n", "x", "o" }, "]m", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
    end, { desc = "Next function [start]" })
    vim.keymap.set({ "n", "x", "o" }, "]M", function()
        require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
    end, { desc = "Next function [end]" })
    vim.keymap.set({ "n", "x", "o" }, "[m", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
    end, { desc = "Previous function [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[M", function()
        require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
    end, { desc = "Previous function [end]" })

    -- CLASS
    vim.keymap.set({ "n", "x", "o" }, "]c", function()
        require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
    end, { desc = "Next class [start]" })
    vim.keymap.set({ "n", "x", "o" }, "]C", function()
        require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects")
    end, { desc = "Next class [end]" })
    vim.keymap.set({ "n", "x", "o" }, "[c", function()
        require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
    end, { desc = "Previous class [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[C", function()
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
    vim.keymap.set({ "n", "x", "o" }, "]o", function()
        require("nvim-treesitter-textobjects.move").goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
    end, { desc = "Next loop [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[o", function()
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
end)
