return {
    "chipsenkbeil/org-roam.nvim",
    event = "VeryLazy",
    dependencies = {
        {
            "nvim-orgmode/orgmode",
            config = function()
                -- Setup orgmode
                require('orgmode').setup({
                    org_agenda_files = '~/Dropbox/neorg/org/**/*',
                    org_default_notes_file = '~/Dropbox/neorg/org/agenda.org',
                    org_startup_indented = true,
                    org_todo_keywords = {'TODO', 'DOING', 'HOLD', 'MAYBE', '|', 'DONE', 'CANCELLED'},
                    mappings = {
                        prefix = "<Leader>O"
                    },
                })
            end,
        },
        {
            'akinsho/org-bullets.nvim',
            config = function()
                require('org-bullets').setup({
                    symbols = {
                        headlines = { "󰼏", "󰼐", "󰼑", "󰼒", "󰼓", "󰼔" },
                    }
                })
            end
        }
    },
    config = function()
        require("org-roam").setup({
            directory = "~/Dropbox/neorg/org/org-roam",
            bindings = {
                prefix = "<leader>OR"
            }
        })
    end
}