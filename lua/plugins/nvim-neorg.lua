return {
    {
        "nvim-neorg/neorg",
        dependencies = { { dir = "~/.config/nvim_plugins/neorg_extras", opts = {} } },
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

            -- local neorg_utils = require("neorg-extras")
            local neorg = require("neorg.core")
            neorg.modules.get_module("core.dirman").set_workspace("default")



            vim.keymap.set("n", "<leader>N_", "<cmd>NeorgExtras Metadata update",
                { noremap = true, silent = true, desc = "Demo" })
            vim.keymap.set("n", "<leader>NFB", "<cmd>Telescope neorg_show_backlinks<cr>",
                { noremap = true, silent = true, desc = "Backlinks" })
            vim.keymap.set("n", "<leader>Nw", "<cmd>Telescope neorg_workspace_selector<cr>",
                { noremap = true, silent = true, desc = "Workspaces" })
            vim.keymap.set("n", "<leader>NFn", "<cmd>Telescope neorg_node_injector<cr>",
                { noremap = true, silent = true, desc = "Node Injector" })
            vim.keymap.set("n", "<leader>Na", "<cmd>NeorgUtils Page undone pending<cr>",
                { noremap = true, silent = true, desc = "Neorg Agenda" })
            vim.keymap.set("n", "<leader>NFb", "<cmd>Telescope neorg_block_injector<cr>",
                { noremap = true, silent = true, desc = "Block Injector" })
            vim.keymap.set("n", "<leader>Nt", "<cmd>Neorg toc<cr>",
                { noremap = true, silent = true, desc = "Table of Contents" })
        end,
    },
}
