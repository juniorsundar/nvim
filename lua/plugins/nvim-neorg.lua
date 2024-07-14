return {
    {
        "nvim-neorg/neorg",
        config = function()
            require("neorg").setup({
                load = {
                    ["core.defaults"] = {},
                    ["core.esupports.indent"] = {
                        config = {
                            tweaks = {
                                unordered_list1 = 0,
                                unordered_list2 = 3,
                                unordered_list3 = 6,
                                unordered_list4 = 9,
                                unordered_list5 = 12,
                                unordered_list6 = 15,
                                ordered_list1 = 0,
                                ordered_list2 = 3,
                                ordered_list3 = 6,
                                ordered_list4 = 9,
                                ordered_list5 = 12,
                                ordered_list6 = 15,
                            },
                        },
                    },
                    ["core.concealer"] = {
                        config = {
                            icon_preset = "diamond",
                            icons = { list = { icons = { "󰧞", "", "", "", "", "" } } },
                        },
                    },
                    ["core.dirman"] = {
                        config = {
                            workspaces = {
                                default = "~/Dropbox/neorg/notes",
                                the_good_teacher = "~/Dropbox/neorg/tgt",
                                god_of_war = "~/Dropbox/neorg/gow",
                            },
                        },
                    },
                    ["core.export"] = {},
                    ["core.export.markdown"] = {},
                    ["core.latex.renderer"] = {},
                    ["core.integrations.image"] = {},
                    ["core.summary"] = {},
                    ["core.qol.toc"] = {},
                    ["core.qol.todo_items"] = {},
                    ["core.looking-glass"] = {},
                    ["core.presenter"] = { config = { zen_mode = "zen-mode" } },
                    ["core.tangle"] = { config = { report_on_empty = false } },
                    ["core.tempus"] = {},
                },
            })

            local neorg_utils = require("custom.neorg_utils")

            vim.keymap.set("n", "<leader>Nb", neorg_utils.show_backlinks,
                { noremap = true, silent = true, desc = "Backlinks" })
            vim.keymap.set("n", "<leader>Nw", neorg_utils.neorg_workspace_selector,
                { noremap = true, silent = true, desc = "Workspaces" })
            vim.keymap.set("n", "<leader>Nf", neorg_utils.neorg_node_injector,
                { noremap = true, silent = true, desc = "Node Injector" })
            vim.keymap.set("n", "<leader>Na", neorg_utils.neorg_agenda,
                { noremap = true, silent = true, desc = "Neorg Agenda" })

        end,
    },
}
