MiniDeps.later(function()
    MiniDeps.add { source = "nvim-orgmode/orgmode", depends = { "chipsenkbeil/org-roam.nvim" } }
    -- Setup orgmode
    require("orgmode").setup {
        mappings = {
            prefix = "<LocalLeader>O",
        },
        org_agenda_files = "~/Dropbox/org/**/*",
        org_default_notes_file = "~/Dropbox/org/refile.org",
        org_todo_keywords = { "TODO(t)", "DOING(d)", "|", "DONE(D)", "CANCELLED(C)" },
    }

    require("org-roam").setup {
        bindings = { prefix = "<LocalLeader>OR" },
        directory = "~/Dropbox/org/pages/",
    }
end)
