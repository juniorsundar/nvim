return {
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        keys = {
            {
                "<C-s>",
                mode = { "n", "x", "o" },
                function()
                    require("flash").jump()
                end,
                desc = "Flash",
            },
            {
                "<C-S-s>",
                mode = { "n", "x", "o" },
                function()
                    require("flash").treesitter()
                end,
                desc = "Flash Treesitter",
            },
            {
                "r",
                mode = "o",
                function()
                    require("flash").remote()
                end,
                desc = "Remote Flash",
            },
            {
                "R",
                mode = { "o", "x" },
                function()
                    require("flash").treesitter_search()
                end,
                desc = "Tresitter Search",
            },
            {
                "<C-s>",
                mode = { "c" },
                function()
                    require("flash").toggle()
                end,
                desc = "Toggle Flash Search",
            },
        },
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        event = "VeryLazy",
        opts = {
            indent = {
                char = "╎",
                tab_char = "╎",
            },
            scope = { enabled = false },
            exclude = {
                filetypes = {
                    "help",
                    "alpha",
                    "dashboard",
                    "neo-tree",
                    "Trouble",
                    "trouble",
                    "lazy",
                    "mason",
                    "notify",
                    "toggleterm",
                    "lazyterm",
                    "norg",
                    "git",
                    "fugitive",
                },
            },
        },
        main = "ibl",
    },
    {
        "mbbill/undotree",
        cmd = "UndotreeToggle",
    },
    {
        "kylechui/nvim-surround",
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to use defaults
            })
        end,
    },
    { "https://github.com/leafo/magick" },
    {
        "3rd/image.nvim",
        ft = { "markdown", "norg" },
        config = function()
            require("image").setup({
                backend = "kitty",
                integrations = {
                    markdown = {
                        enabled = true,
                        clear_in_insert_mode = false,
                        download_remote_images = true,
                        only_render_image_at_cursor = true,
                        filetypes = { "markdown", "vimwiki", "quarto" }, -- markdown extensions (ie. quarto) can go here
                    },
                    neorg = {
                        enabled = true,
                        clear_in_insert_mode = false,
                        download_remote_images = true,
                        only_render_image_at_cursor = true,
                        filetypes = { "norg" },
                    },
                },
                max_width = nil,
                max_height = nil,
                max_width_window_percentage = 50,
                max_height_window_percentage = 50,
                window_overlap_clear_enabled = false,                                     -- toggles images when windows are overlapped
                window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
                editor_only_render_when_focused = false,                                  -- auto show/hide images when the editor gains/looses focus
                tmux_show_only_in_active_window = false,                                  -- auto show/hide images in the correct Tmux window (needs visual-activity off)
                hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
            })
        end,
    },
    {
        "juniorsundar/diagram.nvim",
        dependencies = {
            "3rd/image.nvim",
        },
        config = function()
            require("diagram").setup({ -- you can just pass {}, defaults below
                integrations = {
                    require("diagram.integrations.neorg")
                },
                renderer_options = {
                    mermaid = {
                        background = nil, -- nil | "transparent" | "white" | "#hex"
                        theme = nil,  -- nil | "default" | "dark" | "forest" | "neutral"
                        scale = 1,    -- nil | 1 (default) | 2  | 3 | ...
                    },
                    plantuml = {
                        charset = nil,
                    },
                    d2 = {
                        theme_id = nil,
                        dark_theme_id = nil,
                        scale = nil,
                        layout = nil,
                        sketch = nil,
                    },
                }
            })
        end,
    },
    {
        "OXY2DEV/markview.nvim",
        lazy = false,

        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        }
    },
    {
        "OXY2DEV/helpview.nvim",
        lazy = false,

        dependencies = {
            "nvim-treesitter/nvim-treesitter"
        }
    }
}
