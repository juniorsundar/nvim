return {
    { "https://github.com/leafo/magick" },
    {
        "3rd/image.nvim",
        ft = { "markdown", "norg" },
        config = function()
            require("image").setup {
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
                window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
                window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
                editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
                tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
                hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
            }
        end,
    },
    {
        "3rd/diagram.nvim",
        dependencies = {
            "3rd/image.nvim",
        },
        config = function()
            require("diagram").setup { -- you can just pass {}, defaults below
                integrations = {
                    require "diagram.integrations.neorg",
                },
                renderer_options = {
                    mermaid = {
                        background = nil, -- nil | "transparent" | "white" | "#hex"
                        theme = nil, -- nil | "default" | "dark" | "forest" | "neutral"
                        scale = 1, -- nil | 1 (default) | 2  | 3 | ...
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
                },
            }
        end,
    },
}
