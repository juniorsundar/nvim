return {
    {
        "nvim-neorg/neorg",
        dependencies = { { dir = "~/.config/nvim_plugins/neorg-utils" } },
        config = function()
            require("neorg").setup({
                load = {
                    ["core.defaults"] = {},
                    ["core.esupports.indent"] = {
                        -- config = {
                        --     tweaks = {
                        --         unordered_list1 = 0,
                        --         unordered_list2 = 3,
                        --         unordered_list3 = 6,
                        --         unordered_list4 = 9,
                        --         unordered_list5 = 12,
                        --         unordered_list6 = 15,
                        --         ordered_list1 = 0,
                        --         ordered_list2 = 3,
                        --         ordered_list3 = 6,
                        --         ordered_list4 = 9,
                        --         ordered_list5 = 12,
                        --         ordered_list6 = 15,
                        --     },
                        -- },
                    },
                    ["core.concealer"] = {
                        config = {
                            icon_preset = "varied",
                            icons = {
                                list = { icons = { "󰧞", "", "", "", "", "" } },
                                heading = {
                                    icons = { "󰼏", "󰼐", "󰼑", "󰼒", "󰼓", "󰼔" },
                                },
                            },
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
                    ["core.highlights"] = {},
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
                    ["core.ui.calendar"] = {},
                },
            })

            local neorg_utils = require("neorg-utils")
            local neorg = require("neorg.core")
            neorg.modules.get_module("core.dirman").set_workspace("default")

            -- vim.cmd([[Neorg workspace default]])

            vim.keymap.set("n", "<leader>NFB", neorg_utils.telescopic.show_backlinks,
                { noremap = true, silent = true, desc = "Backlinks" })
            vim.keymap.set("n", "<leader>Nw", neorg_utils.telescopic.neorg_workspace_selector,
                { noremap = true, silent = true, desc = "Workspaces" })
            vim.keymap.set("n", "<leader>NFn", neorg_utils.telescopic.neorg_node_injector,
                { noremap = true, silent = true, desc = "Node Injector" })
            -- vim.keymap.set("n", "<leader>Na", neorg_utils.agenda.neorg_agenda,
            --     { noremap = true, silent = true, desc = "Neorg Agenda" })
            vim.keymap.set("n", "<leader>Na", "<cmd>NeorgUtils Agenda undone pending<cr>",
                { noremap = true, silent = true, desc = "Neorg Agenda" })
            vim.keymap.set("n", "<leader>NFb", neorg_utils.telescopic.neorg_block_injector,
                { noremap = true, silent = true, desc = "Block Injector" })
            vim.keymap.set("n", "<leader>Nt", "<cmd>Neorg toc<cr>",
                { noremap = true, silent = true, desc = "Table of Contents" })
        end,
    },
}
