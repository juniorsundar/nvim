return {
    'nvim-telescope/telescope.nvim',
    enabled = false,
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        require('telescope').setup({
            defaults = {
                sorting_strategy = "ascending",

                -- layout_strategy = "bottom_pane",
                -- layout_config = {
                --     height = 0.5,
                -- },

                layout_strategy = "vertical",
                layout_config = {
                    height = 0.85,
                },
                border = true,
                -- borderchars = {
                --     prompt = { "─", " ", " ", " ", "─", "─", " ", " " },
                --     results = { " " },
                --     preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                -- },
                mappings = {
                    i = {
                        -- map actions.which_key to <C-h> (default: <C-/>)
                        -- actions.which_key shows the mappings for your picker,
                        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
                        ["<C-h>"] = "which_key"
                    }
                }
            },
            pickers = {
                -- Default configuration for builtin pickers goes here:
                -- picker_name = {
                --   picker_config_key = value,
                --   ...
                -- }
                -- Now the picker_config_key will be applied every time you call this
                -- builtin picker
            },
            extensions = {
                -- Your extension configuration goes here:
                -- extension_name = {
                --   extension_config_key = value,
                -- }
                -- please take a look at the readme of the extension you want to configure
            }
        })
    end
}
