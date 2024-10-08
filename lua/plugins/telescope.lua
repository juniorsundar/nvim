return {
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release'
            },
        },
        config = function()
            require('telescope').setup {
                defaults = {
                    layout_strategy = 'bottom_pane',
                    layout_config = {
                        prompt_position = "top",
                        preview_cutoff = 0,
                    },
                    mappings = {
                        i = {
                            ["<C-h>"] = "which_key",
                            ['<C-d>'] = require('telescope.actions').delete_buffer,
                        }
                    },
                },
                pickers = {
                },
                extensions = {
                    fzf = {
                        fuzzy = true,                   -- false will only do exact matching
                        override_generic_sorter = true, -- override the generic sorter
                        override_file_sorter = true,    -- override the file sorter
                        case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
                    },
                }
            }
            -- To get fzf loaded and working with telescope, you need to call
            -- load_extension, somewhere after setup function:
            require('telescope').load_extension('fzf')
        end
    },
    {
        "ibhagwan/fzf-lua",
        -- optional for icon support
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            -- calling `setup` is optional for customization
            local actions = require("fzf-lua.actions")
            require("fzf-lua").setup({
                winopts = {
                    split = "belowright new",
                    preview = {
                        horizontal = "right:50%",
                        delay = 50
                    }
                }
            })
        end
    }
}
