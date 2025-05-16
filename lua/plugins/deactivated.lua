return {
    {
        'nvim-orgmode/orgmode',
        enabled = false,
        dependencies = {
            "chipsenkbeil/org-roam.nvim",
            config = function()
                require("org-roam").setup({
                    directory = "~/Dropbox/org/pages/",
                    bindings = {
                        prefix = "<leader><leader>on"
                    },
                    extensions = {
                        dailies = {
                            directory = "~/Dropbox/org/journals/"
                        }
                    },
                })
            end
        },
        event = 'VeryLazy',
        config = function()
            -- Setup orgmode
            require('orgmode').setup({
                org_agenda_files = '~/Dropbox/org/**/*',
                org_todo_keywords = { 'TODO', 'DOING', '|', 'DONE', 'CANCELLED' },
                org_hide_leading_stars = true,
                org_log_done = "time",
                mappings = {
                    prefix = '<leader><leader>o'
                }
            })
        end,
    },
    {
        -- "hrsh7th/nvim-cmp",
        "iguanacucumber/magazine.nvim",
        enabled = false,
        name = "nvim-cmp",
        version = false,
        dependencies = {
            { "iguanacucumber/mag-nvim-lsp",         name = "cmp-nvim-lsp", opts = {} },
            { "hrsh7th/cmp-nvim-lsp-signature-help", lazy = true },
            "https://codeberg.org/FelipeLema/cmp-async-path"
        },
        config = function()
            local global_snippets = {
                -- { trigger = "shebang", body = "#!/usr/bin/bash" },
            }

            local snippets_by_filetype = {
                -- lua = {
                --     { trigger = "fun", body = "function ${1:name}(${2:args}) $0 end" },
                --     -- other filetypes
                -- },
                -- norg = {
                --     { trigger = "h1", body = '* ${1:text}' }
                -- }
            }

            local function get_buf_snips()
                local ft = vim.bo.filetype
                local snips = vim.list_slice(global_snippets)

                if ft and snippets_by_filetype[ft] then
                    vim.list_extend(snips, snippets_by_filetype[ft])
                end

                return snips
            end

            -- cmp source for snippets to show up in completion menu
            local function register_cmp_source()
                local cmp_source = {}
                local cache = {}
                function cmp_source.complete(_, _, callback)
                    local bufnr = vim.api.nvim_get_current_buf()
                    if not cache[bufnr] then
                        local completion_items = vim.tbl_map(function(s)
                            ---@type lsp.CompletionItem
                            local item = {
                                word = s.trigger,
                                label = s.trigger,
                                kind = vim.lsp.protocol.CompletionItemKind.Snippet,
                                insertText = s.body,
                                insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
                            }
                            return item
                        end, get_buf_snips())

                        cache[bufnr] = completion_items
                    end

                    callback(cache[bufnr])
                end

                require("cmp").register_source("snips", cmp_source)
            end
            register_cmp_source()

            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and
                    vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
            end

            local cmp = require "cmp"

            local kind_icons = {
                Text = "",
                Method = "󰆧",
                Function = "󰊕",
                Constructor = "",
                Field = "󰇽",
                Variable = "󰂡",
                Class = "󰠱",
                Interface = "",
                Module = "",
                Property = "󰜢",
                Unit = "",
                Value = "󰎠",
                Enum = "",
                Keyword = "󰌋",
                Snippet = "",
                Color = "󰏘",
                File = "󰈙",
                Reference = "",
                Folder = "󰉋",
                EnumMember = "",
                Constant = "󰏿",
                Struct = "",
                Event = "",
                Operator = "",
                TypeParameter = "󰅲",
            }

            cmp.setup {
                view = {
                    entries = "custom", -- can be "custom", "wildmenu" or "native"
                },
                formatting = {
                    fields = { "kind", "abbr", "menu" },
                    format = function(entry, vim_item)
                        vim_item.menu = true and "    @" .. entry.source.name .. "" or ""
                        vim_item.kind = " " .. kind_icons[vim_item.kind] .. " "
                        return vim_item
                    end,
                },
                snippet = {
                    completion = {
                        completeopt = "menu,menuone",
                    },
                    expand = function(arg)
                        vim.snippet.expand(arg.body)
                    end,
                },
                window = {
                    documentation = cmp.config.window.bordered {
                        winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None,FloatBorder:Normal",
                    },
                    completion = cmp.config.window.bordered {
                        winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None,FloatBorder:Normal",
                    },
                },
                mapping = cmp.mapping.preset.insert {
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm { select = true }, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        -- Hint: if the completion menu is visible select next one
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }), -- i - insert mode; s - select mode
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                },
                sources = cmp.config.sources {
                    { name = "nvim_lsp" },
                    { name = "snips" },
                    { name = "luasnip" },
                    { name = "async_path" },
                    { name = "nvim_lsp_signature_help" },
                    -- { name = "neorg" },
                    -- { name = "orgmode" },
                },
            }
        end,
    },
    {
        "tpope/vim-fugitive",
        enabled = false,
        lazy = false,
        keys = {
            { "<leader>Gg", "<cmd>tab Git<cr>", desc = "Fugitive" }
        }
    },
    {
        "NeogitOrg/neogit",
        enabled = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        keys = {
            { "<leader>Gg", "<cmd>Neogit cwd=%:p:h<cr>", desc = "Neogit" },
        },
        config = function()
            require("neogit").setup {
                disable_hint = true,
                signs = {
                    hunk = { "", "" },
                    item = { "", "" },
                    section = { "", "" },
                },
                graph_style = "unicode",
                integrations = {
                    telescope = false,
                    diffview = true,
                    fzf_lua = false,
                    mini_pick = false,
                },
            }
        end,
    },
    {
        "obsidian-nvim/obsidian.nvim",
        enabled = false,
        version = "*",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        opts = {
            workspaces = {
                {
                    name = "vault",
                    path = "~/Dropbox/obsidian/vault",
                    overrides = {
                        notes_subdir = "pages",
                        daily_notes = {
                            folder = "journals",
                            template = "journal_template.md"
                        },
                    },
                },
                {
                    name = "gow",
                    path = "~/Dropbox/obsidian/gow",
                },
            },
            completion = {
                nvim_cmp = false,
                blink = true,
                min_chars = 2,
            },
            picker = {
                name = "snacks.pick",
                note_mappings = {
                    new = "<C-x>",
                    insert_link = "<C-l>",
                },
                tag_mappings = {
                    tag_note = "<C-x>",
                    insert_tag = "<C-l>",
                },
            },
            templates = {
                folder = "templates",
                date_format = "%Y-%m-%d",
                time_format = "%H:%M",
                substitutions = {},
            },
            disable_frontmatter = true,
            attachments = {
                img_folder = "assets",
                img_name_func = function()
                    return string.format("%s-", os.time())
                end,

                img_text_func = function(client, path)
                    path = client:vault_relative_path(path) or path
                    return string.format("![%s](%s)", path.name, path)
                end,
            },
        }
    },
    {
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
    },
    {
        "nvim-neorg/neorg",
        enabled = false,
        event = "VeryLazy",
        dependencies = {
            {
                { dir = "~/.config/nvim_plugins/neorg-extras" },
                -- "juniorsundar/neorg-extras",
            },
        },
        keys = {
            { "<leader>NT",  "<cmd>Neorg cycle_task<CR>",                      desc = "Cycle task" },
            { "<leader>N_",  "<cmd>Neorg update_property_metadata<CR>",        desc = "Update property metadata" },
            { "<leader>NFB", "<cmd>Neorg roam backlinks<cr>",                  desc = "Backlinks" },
            { "<leader>Nw",  "<cmd>Neorg roam select_workspace<cr>",           desc = "Workspaces" },
            { "<leader>NFb", "<cmd>Neorg roam block<cr>",                      desc = "Block Injector" },
            { "<leader>NFn", "<cmd>Neorg roam node<cr>",                       desc = "Node Injector" },
            { "<leader>NAd", "<cmd>Neorg agenda day<cr>",                      desc = "Neorg Agenda Day" },
            { "<leader>NAp", "<cmd>Neorg agenda page undone pending hold<cr>", desc = "Neorg Agenda Page" },
            { "<leader>NAt", "<cmd>Neorg agenda tag<cr>",                      desc = "Neorg Agenda Tag" },
            { "<leader>Nt",  "<cmd>Neorg toc<cr>",                             desc = "Table of Contents" },
            { "<leader>Ni",  "<cmd>Neorg index<cr>",                           desc = "Index" },
            { "<leader>NJt", "<cmd>Neorg journal today<cr>",                   desc = "Today's Journal" },
            { "<leader>NJm", "<cmd>Neorg journal tomorrow<cr>",                desc = "Tomorrow's Journal" },
            { "<leader>NJy", "<cmd>Neorg journal yesterday<cr>",               desc = "Yesterday's Journal" },
            { "<leader>NMi", "<cmd>Neorg inject-metadata<cr>",                 desc = "Inject" },
            { "<leader>NMu", "<cmd>Neorg update-metadata<cr>",                 desc = "Update" },
        },
        config = function()
            require("neorg").setup {
                load = {
                    ["core.defaults"] = {},
                    ["core.esupports.indent"] = {},
                    ["core.concealer"] = {
                        config = {
                            icon_preset = "varied",
                            icons = {
                                list = {
                                    icons = { "󰧞", "", "", "", "", "" },
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
                                default = "~/Dropbox/neorg",
                            },
                        },
                    },
                    ["core.export"] = {},
                    ["core.journal"] = {
                        config = {
                            strategy = "flat",
                        },
                    },
                    ["core.highlights"] = {},
                    ["core.export.markdown"] = {},
                    -- ["core.completion"] = {
                    --     config = {
                    --         engine = "nvim-cmp",
                    --     },
                    -- },
                    ["core.latex.renderer"] = {},
                    ["core.integrations.image"] = {},
                    -- ["core.integrations.nvim-cmp"] = {},
                    ["core.summary"] = {},
                    ["core.qol.toc"] = {},
                    ["core.qol.todo_items"] = {},
                    ["core.looking-glass"] = {},
                    ["core.presenter"] = {
                        config = {
                            zen_mode = "zen-mode",
                        },
                    },
                    ["core.tangle"] = {
                        config = {
                            report_on_empty = false,
                        },
                    },
                    ["core.tempus"] = {},
                    ["core.ui.calendar"] = {},
                    ["external.agenda"] = {},
                    ["external.roam"] = {
                        config = {
                            fuzzy_finder = "Fzf",
                            fuzzy_backlinks = false,
                            roam_base_directory = "vault",
                            node_name_randomiser = false,
                            node_name_snake_case = true,
                        },
                    },
                    ["external.many-mans"] = {
                        config = {
                            metadata_fold = true,
                            code_fold = false,
                        },
                    },
                },
            }

            require("neorg.core").modules.get_module("core.dirman").set_workspace "default"
        end,
    },
    {
        "3rd/diagram.nvim",
        enabled = false,
        ft = { "markdown", "norg" },
        dependencies = {
            {
                "3rd/image.nvim",
                event = "VeryLazy",
                config = function()
                    require("image").setup {
                        backend = "kitty",
                        integrations = {
                            markdown = {
                                enabled = true,
                                clear_in_insert_mode = false,
                                download_remote_images = true,
                                only_render_image_at_cursor = true,
                                filetypes = { "markdown", "vimwiki", "quarto" }, -- markdown extensions (ie. quarto) can go here
                            },
                            neorg = {
                                enabled = true,
                                clear_in_insert_mode = false,
                                download_remote_images = true,
                                only_render_image_at_cursor = true,
                                filetypes = { "norg" },
                            },
                        },
                        max_width = nil,
                        max_height = nil,
                        max_width_window_percentage = 50,
                        max_height_window_percentage = 50,
                        window_overlap_clear_enabled = false,                                     -- toggles images when windows are overlapped
                        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
                        editor_only_render_when_focused = false,                                  -- auto show/hide images when the editor gains/looses focus
                        tmux_show_only_in_active_window = false,                                  -- auto show/hide images in the correct Tmux window (needs visual-activity off)
                        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
                    }
                end,
            },
        },
        config = function()
            require("diagram").setup { -- you can just pass {}, defaults below
                integrations = {
                    require "diagram.integrations.neorg",
                },
                renderer_options = {
                    mermaid = {
                        background = nil, -- nil | "transparent" | "white" | "#hex"
                        theme = nil,      -- nil | "default" | "dark" | "forest" | "neutral"
                        scale = 1,        -- nil | 1 (default) | 2  | 3 | ...
                    },
                    plantuml = {
                        charset = nil,
                    },
                    d2 = {
                        theme_id = nil,
                        dark_theme_id = nil,
                        scale = nil,
                        layout = nil,
                        sketch = nil,
                    },
                },
            }
        end,
    },
    {
        "ibhagwan/fzf-lua",
        enabled = false,
        keys = {
            { "<leader>b",   "<cmd>FzfLua buffers<cr>",                   desc = "Buffers" },
            { "<leader>Ff",  "<cmd>FzfLua files<cr>",                     desc = "Files" },
            { "<leader>Ft",  "<cmd>FzfLua live_grep<CR>",                 desc = "Text" },
            { "<leader>Fc",  "<cmd>FzfLua colorschemes<cr>",              desc = "Colorscheme" },
            { "<leader>Fh",  "<cmd>FzfLua helptags<cr>",                  desc = "Find Help" },
            { "<leader>Fk",  "<cmd>FzfLua keymaps<cr>",                   desc = "Keymaps" },
            { "<leader>Fr",  "<cmd>FzfLua oldfiles<cr>",                  desc = "Open Recent File" },
            { "<leader>FM",  "<cmd>FzfLua manpages<cr>",                  desc = "Man Pages" },
            { "<leader>FR",  "<cmd>FzfLua registers<cr>",                 desc = "Registers" },
            { "<leader>FC",  "<cmd>FzfLua commands<cr>",                  desc = "Commands" },
            { "<leader>Fl",  "<cmd>FzfLua grep_curbuf<cr>",               desc = "Line" },
            { "<leader>Go",  "<cmd>FzfLua git_status <cr>",               desc = "Open changed file" },
            { "<leader>Gb",  "<cmd>FzfLua git_branches <cr>",             desc = "Checkout branch" },
            { "<leader>Lr",  "<cmd>FzfLua lsp_references<cr>",            desc = "References" },
            { "<leader>Lt",  "<cmd>FzfLua lsp_typedefs<cr>",              desc = "Type Definition" },
            { "<leader>LDd", "<cmd>FzfLua lsp_document_diagnostics<cr>",  desc = "Document Diagnostics" },
            { "<leader>LDs", "<cmd>FzfLua lsp_document_symbols <cr>",     desc = "Document Symbols" },
            { "<leader>LWd", "<cmd>FzfLua lsp_workspace_diagnostics<cr>", desc = "Workspace Diagnostics" },
            { "<leader>LWs", "<cmd>FzfLua lsp_workspace_symbols <cr>",    desc = "Workspace Symbols" },
        },
        config = function()
            -- calling `setup` is optional for customization
            local actions = require "fzf-lua.actions"
            require("fzf-lua").setup {
                winopts = {
                    split = "belowright new",
                    preview = {
                        horizontal = "right:50%",
                        delay = 50,
                    },
                },
            }
        end,
    },
}
