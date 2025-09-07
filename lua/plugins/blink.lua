---@diagnostic disable: missing-fields
return {
    "saghen/blink.cmp",
    enabled = true,
    -- optional: provides snippets for the snippet source
    -- dependencies = 'rafamadriz/friendly-snippets',
    lazy = true,
    -- event = "VeryLazy",
    -- use a release tag to download pre-built binaries
    version = "v1.*",
    -- build = (vim.fn.executable "nix" == 1) and "nix run .#build-plugin" or "cargo build --release",

    ---@module 'blink.cmp'
    -- stylua: ignore
    opts = {
        -- 'default' for mappings similar to built-in completion
        -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
        -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
        -- See the full "keymap" documentation for information on defining your own keymap.
        fuzzy = {
            implementation = 'prefer_rust',
            prebuilt_binaries = {
                download = true,
            }
        },
        keymap = {
            preset = 'enter',
            ["<Tab>"] = { 'select_next', 'fallback' },
            ["<S-Tab>"] = { 'select_prev', 'fallback' },
            ["<C-n>"] = { 'snippet_forward', 'fallback' },
            ["<C-p>"] = { 'snippet_backward', 'fallback' },
            ["<C-Down>"] = { 'scroll_documentation_down', 'fallback' },
            ["<C-Up>"] = { 'scroll_documentation_up', 'fallback' },
        },

        appearance = {
            -- Sets the fallback highlight groups to nvim-cmp's highlight groups
            -- Useful for when your theme doesn't support blink.cmp
            -- Will be removed in a future release
            -- use_nvim_cmp_as_default = true,
            -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
            -- Adjusts spacing to ensure icons are aligned
            nerd_font_variant = 'normal'
        },

        cmdline = {
            enabled = true,
            keymap = {
                preset = 'inherit',
            },
            completion = {
                menu = {
                    auto_show = function(ctx)
                        return vim.fn.getcmdtype() == ':'
                    end,
                },
                list = {
                    selection = {
                        preselect = false,
                        auto_insert = false,
                    }
                },
            },
        },
        -- Default list of enabled providers defined so that you can extend it
        -- elsewhere in your config, without redefining it, due to `opts_extend`
        sources = {
            default = { 'lsp', 'path', 'snippets', 'buffer' },
            per_filetype = {
                markdown = { "obsidian", "obsidian_new", "obsidian_tags" },
            },
            providers = {
                lazydev = {
                    name = "LazyDev",
                    module = "lazydev.integrations.blink",
                    score_offset = 100,
                },
            },
        },
        completion = {
            menu = {
                -- winhighlight = "Normal:BlinkCmpPmenu,Normal:BlinkCmpCursorLine,Search:None,FloatBorder:FloatBorder",
                border = 'rounded',
                draw = {
                    treesitter = { 'lsp', 'path', 'snippets', 'buffer', "lazydev" },
                },
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 50,
                window = { border = 'single' }
            },
            list = {
                selection = {
                    preselect = false,
                    auto_insert = false,
                }
            },
            ghost_text = {
                enabled = false,
            }
        },
        signature = {
            enabled = true,
            window = {
                border = 'single',
            }
        },
    },
    opts_extend = { "sources.default" },
}
