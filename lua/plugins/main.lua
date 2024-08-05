return {
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = {}
    },
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            bigfile = { enabled = true },
            dashboard = {
                enabled = true,
                preset = {
                    keys = {
                        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                        { icon = " ", key = "t", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                        { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                        { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                    }
                },
                sections = {
                    { section = "header" },
                    { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
                    { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
                    { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                    { section = "startup" },
                },
            },
            notifier = {
                enabled = true,
                timeout = 3000,
            },
            quickfile = { enabled = true },
            statuscolumn = { enabled = true },
            input = { enabled = true },
            scroll = { enabled = true },
            indent = { enabled = false },
            words = { enabled = true },
            styles = {
                notification = {
                    wo = { wrap = true },
                },
                blame_line = {
                    width = 0.8,
                    height = 0.8,
                },
            },
            toggle = {},
            picker = {
                matcher = {
                    frecency = true
                },
                ui_select = true,
                sources = {
                    lsp_symbols = {
                        finder = "lsp_symbols",
                        format = "lsp_symbol",
                        hierarchy = true,
                        filter = { default = true, markdown = true, help = true, lua = true, go = true },
                    },
                },
                formatters = {
                    file = {
                        filename_first = true,
                    },
                },
                file = {
                    max_size = 10 * 1024 * 1024,
                    max_line_length = 5000,
                },
                previewers = {
                    git = {
                        native = true
                    }
                },
                layout = {
                    cycle = true,
                    preset = function() return vim.o.columns >= 140 and "ivy" or "default" end
                },
                win = {
                    input = {
                        keys = {
                            ["<Esc>"] = { "close", mode = { "n", "i" } },
                            ["<C-c>"] = "close",
                            ["<C-Up>"] = { "preview_scroll_up", mode = { "i", "n" } },
                            ["<C-Down>"] = { "preview_scroll_down", mode = { "i", "n" } },
                            ["<C-b>"] = { "history_back", mode = { "i", "n" } },
                            ["<C-f>"] = { "history_forward", mode = { "i", "n" } },
                        }
                    }
                }
            },
        },
        keys = {
            { "<leader>n",   function() Snacks.notifier.hide() end,                desc = "Dismiss All Notifications" },
            { "<leader>Gw",  function() Snacks.gitbrowse() end,                    desc = "Git Browse" },
            { "<leader>Go",  function() Snacks.picker.git_status() end,            desc = "Open changed file" },
            { "<leader>GL",  function() Snacks.lazygit() end,                      desc = "Lazygit" },
            { "<leader>t",   function() Snacks.terminal() end,                     desc = "Terminal" },
            { "<leader>b",   function() Snacks.picker.buffers() end,               desc = "Buffers" },
            { "<leader>Fp",  function() Snacks.picker() end,                       desc = "Pickers" },
            { "<leader>Ff",  function() Snacks.picker.files() end,                 desc = "Files" },
            { "<leader>Ft",  function() Snacks.picker.grep() end,                  desc = "Text" },
            { "<leader>Fl",  function() Snacks.picker.lines() end,                 desc = "Line" },
            { "<leader>Fc",  function() Snacks.picker.colorschemes() end,          desc = "Colorscheme" },
            { "<leader>Fh",  function() Snacks.picker.help() end,                  desc = "Find Help" },
            { "<leader>Fk",  function() Snacks.picker.keymaps() end,               desc = "Keymaps" },
            { "<leader>Fr",  function() Snacks.picker.recent() end,                desc = "Recent File" },
            { "<leader>FM",  function() Snacks.picker.man() end,                   desc = "Man Pages" },
            { "<leader>FR",  function() Snacks.picker.registers() end,             desc = "Registers" },
            { "<leader>FC",  function() Snacks.picker.commands() end,              desc = "Commands" },
            { "<leader>Fu",  function() Snacks.picker.undo() end,                  desc = "Undo" },
            { "<leader>Fe",  function() Snacks.picker.explorer() end,              desc = "Explorer" },
            { "<leader>Lr",  function() Snacks.picker.lsp_references() end,        desc = "References" },
            { "<leader>Lt",  function() Snacks.picker.lsp_type_definitions() end,  desc = "Type Definition" },
            { "<leader>LDs", function() Snacks.picker.lsp_symbols() end,           desc = "Document Symbols" },
            { "<leader>LDd", function() Snacks.picker.diagnostics_buffer() end,    desc = "Document Diagnostics" },
            { "<leader>LWs", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Workspace Symbols" },
            { "<leader>LWd", function() Snacks.picker.diagnostics() end,           desc = "Workspace Diagnostics" },
            {
                "<localleader>N",
                desc = "Neovim News",
                function()
                    Snacks.win {
                        file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
                        width = 0.8,
                        height = 0.8,
                        wo = {
                            spell = false,
                            wrap = false,
                            signcolumn = "yes",
                            statuscolumn = " ",
                            conceallevel = 3,
                        },
                    }
                end,
            },
        },
        init = function()
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                callback = function()
                    _G.dd = function(...)
                        Snacks.debug.inspect(...)
                    end
                    _G.bt = function()
                        Snacks.debug.backtrace()
                    end
                    vim.print = _G.dd -- Override print to use snacks for `:=` command
                    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader><leader>Ts")
                    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader><leader>Tw")
                    Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader><leader>TL")
                    Snacks.toggle.diagnostics():map("<leader><leader>Td")
                    Snacks.toggle.line_number():map("<leader><leader>Tl")
                    Snacks.toggle.option("conceallevel",
                        { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader><leader>Tc")
                    Snacks.toggle.treesitter():map("<leader><leader>TT")
                    Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map(
                        "<leader><leader>Tb")
                    Snacks.toggle.inlay_hints():map("<leader><leader>Th")
                    Snacks.toggle.indent():map("<leader><leader>Tg")
                    Snacks.toggle.dim():map("<leader><leader>TD")
                end,
            })
            vim.api.nvim_create_autocmd("LspProgress", {
                callback = function(ev)
                    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
                    vim.notify(vim.lsp.status(), "info", {
                        id = "lsp_progress",
                        title = "LSP Progress",
                        opts = function(notif)
                            notif.icon = ev.data.params.value.kind == "end" and " "
                                or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
                        end,
                    })
                end,
            })
            require("snacks.picker.config.layouts").default = {
                layout = {
                    box = "vertical",
                    backdrop = false,
                    row = -1,
                    width = 0,
                    height = 0.5,
                    border = "top",
                    title = " {source} {live}",
                    title_pos = "left",
                    { win = "input", height = 1, border = "bottom" },
                    {
                        box = "vertical",
                        { win = "list",    border = "none" },
                        { win = "preview", height = 0.6,   border = "top" },
                    },
                },
            }
            require("snacks.picker.config.layouts").ivy = {
                layout = {
                    box = "vertical",
                    backdrop = false,
                    row = -1,
                    width = 0,
                    height = 0.5,
                    border = "top",
                    title = " {source} {live}",
                    title_pos = "left",
                    { win = "input", height = 1, border = "bottom" },
                    {
                        box = "horizontal",
                        { win = "list",    border = "none" },
                        { win = "preview", width = 0.6,    border = "left" },
                    },
                },
            }
            require("snacks.picker.config.layouts").sidebar.layout.position = "right"
        end,
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 500
            require("which-key.colors").Normal = "NormalFloat"
        end,
        opts = {
            preset = "modern",
            icons = {
                rules = false,
            },
            win = {
                row = -1,
                padding = { 1, 2 },
                title = true,
                title_pos = "center",
                zindex = 1000,
            },
            layout = {
                width = { min = 20 },
                spacing = 3,
                align = "center",
            },
            spec = {
                { "<leader>w",         "<cmd>w!<cr>",                                        desc = "Save" },
                { "<leader>q",         "<cmd>q<cr>",                                         desc = "Quit" },
                { "<leader>l",         "<cmd>Lazy<cr>",                                      desc = "Lazy" },
                { "<leader>m",         "<cmd>Mason<cr>",                                     desc = "Mason" },
                { "<leader>o",         "<cmd>Oil<cr>",                                       desc = "Oil" },
                { "<leader>L",         group = "LSP" },
                { "<leader>LD",        group = "Document" },
                { "<leader>LW",        group = "Workspace" },
                { "<leader>La",        "<cmd>lua vim.lsp.buf.code_action()<cr>",             desc = "Code Action" },
                { "<leader>Ld",        "<cmd>lua vim.lsp.buf.definition()<cr>",              desc = "Definition" },
                { "<leader>Li",        "<cmd>lua vim.lsp.buf.implementation()<cr>",          desc = "Implementation" },
                { "<leader>Lc",        "<cmd>lua vim.lsp.buf.declaration()<cr>",             desc = "Declaration" },
                { "<leader>Lf",        "<cmd>lua vim.lsp.buf.format{async=true}<cr>",        desc = "Format" },
                { "<leader>Ll",        "<cmd>lua vim.lsp.codelens.run()<cr>",                desc = "CodeLens Action" },
                { "<leader>Ln",        "<cmd>lua vim.lsp.buf.rename()<cr>",                  desc = "Rename" },
                { "<leader>Lk",        "<cmd>lua vim.lsp.buf.hover()<cr>",                   desc = "Hover" },
                { "<leader>LI",        "<cmd>LspInfo<cr>",                                   desc = "LSP Info" },
                { "<leader>LWa",       "<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>",    desc = "Add Workspace Folder" },
                { "<leader>LWr",       "<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>", desc = "Remove Workspace Folder" },
                { "<leader>LWl",       "<cmd>lua vim.lsp.buf.list_workspace_folders()<cr>",  desc = "List Workspace Folders" },
                { "<leader>F",         desc = "Find" },
                { "<leader>G",         group = "Git" },
                { "<leader><leader>T", group = "Toggle" },
                { "<leader><leader>",  group = "LocalLeader" },
            },
        },
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        keys = {
            { "<C-s>",   mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
            { "<C-M-s>", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
            { "gr",      mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
            { "gR",      mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
        },
        config = function()
            require("flash").setup()
        end
    },
    {
        "kylechui/nvim-surround",
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup()
        end,
    },
    {
        "echasnovski/mini.pairs",
        event = "VeryLazy",
        config = function()
            require("mini.pairs").setup()
        end,
    },
    {
        "echasnovski/mini.ai",
        event = "VeryLazy",
        config = function()
            require("mini.ai").setup()
        end,
    },
    {
        "echasnovski/mini.move",
        event = "VeryLazy",
        config = function()
            require("mini.move").setup()
        end,
    },
    {
        "stevearc/oil.nvim",
        config = function()
            require("oil").setup {
                columns = {
                    "size",
                    "icon",
                },
                view_options = {
                    show_hidden = true,
                },
            }
        end,
    },
    {
        'stevearc/quicker.nvim',
        event = "FileType qf",
        config = function()
            require("quicker").setup({
                keys = {
                    {
                        ">",
                        function()
                            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
                        end,
                        desc = "Expand quickfix context",
                    },
                    {
                        "<",
                        function()
                            require("quicker").collapse()
                        end,
                        desc = "Collapse quickfix context",
                    },
                },
            })
        end
    },
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            local lualine = require "lualine"
            local cyberdream = {
                bg       = '#1e2124',
                blue     = '#5ea1ff',
                cyan     = '#64d8cb',
                darkblue = '#081633',
                fg       = '#ffffff',
                green    = '#5eff6c',
                magenta  = '#ff5ef1',
                orange   = '#ffbd5e',
                red      = '#ff6e5e',
                violet   = '#bd5eff',
                yellow   = '#f1ff5e',
            }
            local colors = cyberdream
            local conditions = {
                buffer_not_empty = function()
                    return vim.fn.empty(vim.fn.expand "%:t") ~= 1
                end,
                hide_in_width = function()
                    return vim.fn.winwidth(0) > 80
                end,
                check_git_workspace = function()
                    local filepath = vim.fn.expand "%:p:h"
                    local gitdir = vim.fn.finddir(".git", filepath .. ";")
                    return gitdir and #gitdir > 0 and #gitdir < #filepath
                end,
            }
            local config = {
                options = {
                    disabled_filetypes = {
                        "NeogitStatus",
                        "snacks_dashboard",
                        "oil",
                        "ministarter",
                        "fzf",
                    },
                    component_separators = "",
                    section_separators = "",
                    theme = {
                        normal = { c = { fg = colors.fg, bg = colors.bg } },
                        inactive = { c = { fg = colors.fg, bg = colors.bg } },
                    },
                },
                sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_y = {},
                    lualine_z = {},
                    lualine_c = {},
                    lualine_x = {},
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_y = {},
                    lualine_z = {},
                    lualine_c = { "filename" },
                    lualine_x = { "location" },
                },
            }
            local function ins_left(component)
                table.insert(config.sections.lualine_c, component)
            end
            local function ins_right(component)
                table.insert(config.sections.lualine_x, component)
            end
            ins_left {
                function()
                    return ""
                end,
                color = function()
                    local mode_color = {
                        n = colors.blue,
                        i = colors.red,
                        v = colors.green,
                        ["\22"] = colors.green,
                        V = colors.green,
                        c = colors.magenta,
                        no = colors.red,
                        s = colors.orange,
                        S = colors.orange,
                        ["\19"] = colors.orange,
                        ic = colors.yellow,
                        R = colors.violet,
                        Rv = colors.violet,
                        cv = colors.red,
                        ce = colors.red,
                        r = colors.cyan,
                        rm = colors.cyan,
                        ["r?"] = colors.cyan,
                        ["!"] = colors.red,
                        t = colors.red,
                    }
                    return { bg = mode_color[vim.fn.mode()] }
                end,
                padding = { left = 0, right = 1 },
            }
            ins_left {
                "mode",
                color = function()
                    local mode_color = {
                        n = colors.blue,
                        i = colors.red,
                        v = colors.green,
                        ["\22"] = colors.green,
                        V = colors.green,
                        c = colors.magenta,
                        no = colors.red,
                        s = colors.orange,
                        S = colors.orange,
                        ["\19"] = colors.orange,
                        ic = colors.yellow,
                        R = colors.violet,
                        Rv = colors.violet,
                        cv = colors.red,
                        ce = colors.red,
                        r = colors.cyan,
                        rm = colors.cyan,
                        ["r?"] = colors.cyan,
                        ["!"] = colors.red,
                        t = colors.red,
                    }
                    return { bg = mode_color[vim.fn.mode()], fg = colors.bg }
                end,
                padding = { left = 1, right = 1 },
            }
            ins_left {
                "branch",
                icon = "",
                color = { fg = colors.violet, gui = "bold" },
                padding = { left = 1, right = 1 },
            }
            ins_left {
                "diagnostics",
                sources = { "nvim_diagnostic" },
                symbols = { error = " ", warn = " ", info = " " },
                diagnostics_color = {
                    error = { fg = colors.red },
                    warn = { fg = colors.yellow },
                    info = { fg = colors.cyan },
                },
            }
            ins_left {
                "filename",
                cond = conditions.buffer_not_empty,
                color = { fg = colors.fg, gui = "bold" },
            }
            ins_left {
                function()
                    return "%="
                end,
            }
            ins_right {
                "filetype",
                icons_enabled = true,
                color = { gui = "italic" },
            }
            ins_right { "location" }
            ins_right { "progress", color = { fg = colors.fg, gui = "bold" } }
            ins_right {
                function()
                    return "▊"
                end,
                color = function()
                    local mode_color = {
                        n = colors.blue,
                        i = colors.red,
                        v = colors.green,
                        ["\22"] = colors.green,
                        V = colors.green,
                        c = colors.magenta,
                        no = colors.red,
                        s = colors.orange,
                        S = colors.orange,
                        ["\19"] = colors.orange,
                        ic = colors.yellow,
                        R = colors.violet,
                        Rv = colors.violet,
                        cv = colors.red,
                        ce = colors.red,
                        r = colors.cyan,
                        rm = colors.cyan,
                        ["r?"] = colors.cyan,
                        ["!"] = colors.red,
                        t = colors.red,
                    }
                    return { fg = mode_color[vim.fn.mode()] }
                end,
                padding = { left = 1 },
            }
            lualine.setup(config)
        end,
    },
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        keys = {
            { "<leader>Gg", "<cmd>Neogit cwd=%:p:h<cr>", desc = "Neogit" },
        },
        config = function()
            require("neogit").setup {
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
        "lewis6991/gitsigns.nvim",
        event = "VeryLazy",
        dependencies = {
            "sindrets/diffview.nvim",
        },
        keys = {
            { "<leader>Gd", "<cmd>Gitsigns diffthis HEAD<cr>",                    desc = "Diff" },
            { "<space>G]",  "<cmd>lua require('gitsigns').next_hunk()<cr>",       desc = "Next Hunk" },
            { "<space>G[",  "<cmd>lua require('gitsigns').prev_hunk()<cr>",       desc = "Previous Hunk" },
            { "<space>Gp",  "<cmd>lua require('gitsigns').preview_hunk()<cr>",    desc = "Preview Hunk" },
            { "<space>Gr",  "<cmd>lua require('gitsigns').reset_hunk()<cr>",      desc = "Reset Hunk" },
            { "<space>Gs",  "<cmd>lua require('gitsigns').stage_hunk()<cr>",      desc = "Stage Hunk" },
            { "<space>Gu",  "<cmd>lua require('gitsigns').undo_stage_hunk()<cr>", desc = "Undo Stage Hunk" },
            { "<space>GR",  "<cmd>lua require('gitsigns').reset_buffer()<cr>",    desc = "Reset Buffer" },
            { "<space>GB",  "<cmd>lua require('gitsigns').blame()<cr>",           desc = "Blame" },
            { "<space>Gl",  "<cmd>lua require('gitsigns').blame_line()<cr>",      desc = "Blame Line" }
        },
        config = function()
            require("gitsigns").setup {
                signs = {
                    add = { text = "┃" },
                    change = { text = "┃" },
                    delete = { text = "-" }, -- '_'
                    topdelete = { text = "" }, -- '‾'
                    changedelete = { text = "~" },
                    untracked = { text = "┆" },
                },
                signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
                numhl = false,     -- Toggle with `:Gitsigns toggle_numhl`
                linehl = false,    -- Toggle with `:Gitsigns toggle_linehl`
                word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
                watch_gitdir = {
                    follow_files = true,
                },
                attach_to_untracked = true,
                current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
                current_line_blame_opts = {
                    virt_text = true,
                    virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
                    delay = 1000,
                    ignore_whitespace = false,
                    virt_text_priority = 100,
                },
                current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
                sign_priority = 6,
                update_debounce = 100,
                status_formatter = nil,  -- Use default
                max_file_length = 40000, -- Disable if file is longer than this (in lines)
                preview_config = {
                    -- Options passed to nvim_open_win
                    border = "single",
                    style = "minimal",
                    relative = "cursor",
                    row = 0,
                    col = 1,
                },
            }
        end,
    },
}
