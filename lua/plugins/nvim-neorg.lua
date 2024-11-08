return {
    {
        "nvim-neorg/neorg",
        event = "VeryLazy",
        dependencies = { {
            dir = "~/.config/nvim_plugins/neorg-extras",
            -- {
            --     "juniorsundar/neorg-extras",
            --     tag = "v0.5.0"
            -- }
        },
        },
        config = function()
            require("neorg").setup({
                load = {
                    ["core.defaults"] = {},
                    ["core.esupports.indent"] = {},
                    ["core.concealer"] = {
                        config = {
                            icon_preset = "varied",
                            icons = {
                                list = {
                                    icons = { "󰧞", "", "", "", "", "" }
                                },
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
                    ["core.journal"] = {
                        config = {
                            strategy = "flat"
                        }
                    },
                    ["core.highlights"] = {},
                    ["core.export.markdown"] = {},
                    ["core.completion"] = {
                        config = {
                            engine = "nvim-cmp",
                        }
                    },
                    ["core.latex.renderer"] = {},
                    ["core.integrations.image"] = {},
                    ["core.integrations.nvim-cmp"] = {},
                    ["core.summary"] = {},
                    ["core.qol.toc"] = {},
                    ["core.qol.todo_items"] = {},
                    ["core.looking-glass"] = {},
                    ["core.presenter"] = {
                        config = {
                            zen_mode = "zen-mode",
                        }
                    },
                    ["core.tangle"] = {
                        config = {
                            report_on_empty = false,
                        }
                    },
                    ["core.tempus"] = {},
                    ["core.ui.calendar"] = {},
                    ["external.agenda"] = {},
                    ["external.roam"] = {
                        config = {
                            fuzzy_finder = "Fzf",
                            fuzzy_backlinks = false,
                            roam_base_directory = "vault"
                        }
                    },
                    ["external.many-mans"] = {
                        config = {
                            metadata_fold = true,
                            code_fold = false,
                        }
                    },
                },
            })

            require("neorg.core").modules.get_module("core.dirman").set_workspace("default")

            vim.keymap.set("n", "<leader>NT", "<cmd>Neorg cycle_task<CR>",
                { noremap = true, silent = true, desc = "Cycle task" })
            vim.keymap.set("n", "<leader>N_", "<cmd>Neorg update_property_metadata<CR>",
                { noremap = true, silent = true, desc = "Update property metadata" })
            vim.keymap.set("n", "<leader>NFB", "<cmd>Neorg roam backlinks<cr>",
                { noremap = true, silent = true, desc = "Backlinks" })
            vim.keymap.set("n", "<leader>Nw", "<cmd>Neorg roam select_workspace<cr>",
                { noremap = true, silent = true, desc = "Workspaces" })
            vim.keymap.set("n", "<leader>NFb", "<cmd>Neorg roam block<cr>",
                { noremap = true, silent = true, desc = "Block Injector" })
            vim.keymap.set("n", "<leader>NFn", "<cmd>Neorg roam node<cr>",
                { noremap = true, silent = true, desc = "Node Injector" })
            vim.keymap.set("n", "<leader>NAd", "<cmd>Neorg agenda day<cr>",
                { noremap = true, silent = true, desc = "Neorg Agenda Day" })
            vim.keymap.set("n", "<leader>NAp", "<cmd>Neorg agenda page undone pending hold<cr>",
                { noremap = true, silent = true, desc = "Neorg Agenda Page" })
            vim.keymap.set("n", "<leader>NAt", "<cmd>Neorg agenda tag<cr>",
                { noremap = true, silent = true, desc = "Neorg Agenda Tag" })
            vim.keymap.set("n", "<leader>Nt", "<cmd>Neorg toc<cr>",
                { noremap = true, silent = true, desc = "Table of Contents" })
        end,
    },
}
