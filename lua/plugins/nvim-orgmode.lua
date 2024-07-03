return {
    'nvim-orgmode/orgmode',
    dependencies = {
        {
            "akinsho/org-bullets.nvim",
            config = function()
                require("org-bullets").setup {
                    concealcursor = true,
                    symbols = {
                        list = "•",
                        headlines = { "◈", "◇", "◆", "⋄", "❖", "⟡" },
                        checkboxes = {
                            half = { "", "@org.checkbox.halfchecked" },
                            done = { "✓", "@org.keyword.done" },
                            todo = { "˟", "@org.keyword.todo" },
                        },
                    }
                }
            end
        },
        {
            "chipsenkbeil/org-roam.nvim",
            config = function()
                require("org-roam").setup({
                    directory = "~/Dropbox/neorg/org/org-roam",
                    bindings = {
                        prefix = "<Leader><Leader>n",
                    }
                })
            end
        }
    },
    event = 'VeryLazy',
    ft = { 'org' },
    config = function()
        -- Setup orgmode
        require('orgmode').setup({
            org_agenda_files = '~/Dropbox/neorg/org/**/*',
            org_default_notes_file = '~/Dropbox/neorg/org/refile.org',
            mappings = {
                prefix = '<Leader><Leader>o',
            },
            org_todo_keywords = { 'TODO', 'DOING', 'HOLD', 'MAYBE', '|', 'CANCELLED', 'DONE' },
        })
    end,
}
