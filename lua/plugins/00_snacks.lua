MiniDeps.now(function()
    MiniDeps.add { source = "folke/snacks.nvim" }
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            _G.dd = function(...)
                Snacks.debug.inspect(...)
            end
            ---@diagnostic disable-next-line: duplicate-set-field
            _G.bt = function()
                Snacks.debug.backtrace()
            end
            vim.print = _G.dd -- Override print to use snacks for `:=` command
            Snacks.toggle.option("spell", { name = "Spelling" }):map "<leader><leader>Ts"
            Snacks.toggle.option("wrap", { name = "Wrap" }):map "<leader><leader>Tw"
            Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map "<leader><leader>TL"
            Snacks.toggle.diagnostics():map "<leader><leader>Td"
            Snacks.toggle.line_number():map "<leader><leader>Tl"
            Snacks.toggle
                .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
                :map "<leader><leader>Tc"
            Snacks.toggle.treesitter():map "<leader><leader>TT"
            Snacks.toggle
                .option("background", { off = "light", on = "dark", name = "Dark Background" })
                :map "<leader><leader>Tb"
            Snacks.toggle.inlay_hints():map "<leader><leader>Ti"
            Snacks.toggle.indent():map "<leader><leader>Tg"
            Snacks.toggle.dim():map "<leader><leader>TD"
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
    require("snacks.picker.config.layouts").ivy = {
        layout = {
            backdrop = false,
            border = "top",
            box = "vertical",
            { win = "preview", title = "{preview}", height = 0.65 },
            {
                title = " {source} {live}",
                win = "input",
                height = 1.0,
                border = "top",
            },
            { win = "list", height = 0.3, border = "top" },
        },
    }
    require("snacks.picker.config.layouts").sidebar.layout.position = "right"

    require("snacks").setup {
        bigfile = { enabled = true },
        dashboard = {
            enabled = true,
            preset = {
                keys = {
                    {
                        icon = " ",
                        key = "f",
                        desc = "Find File",
                        action = function()
                            Snacks.picker.files { hidden = true }
                        end,
                    },
                    {
                        icon = " ",
                        key = "n",
                        desc = "New File",
                        action = function()
                            vim.cmd ":ene | startinsert"
                        end,
                    },
                    {
                        icon = " ",
                        key = "t",
                        desc = "Find Text",
                        action = function()
                            Snacks.dashboard.pick "live_grep"
                        end,
                    },
                    {
                        icon = " ",
                        key = "r",
                        desc = "Recent Files",
                        action = function()
                            Snacks.dashboard.pick "oldfiles"
                        end,
                    },
                    {
                        icon = " ",
                        key = "c",
                        desc = "Config",
                        action = function()
                            Snacks.dashboard.pick("files", { cwd = vim.fn.stdpath "config" })
                        end,
                    },
                    -- { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                    { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                },
            },
            sections = {
                { section = "header" },
                -- {
                --     pane = 2,
                --     section = "terminal",
                --     cmd = "colorscript -e square",
                --     height = 5,
                --     padding = 1,
                -- },
                { section = "keys", gap = 1, padding = 1 },
                { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
                { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                {
                    pane = 2,
                    icon = " ",
                    title = "Git Status",
                    section = "terminal",
                    enabled = function()
                        return Snacks.git.get_root() ~= nil
                    end,
                    cmd = "git status --short --branch --renames",
                    height = 5,
                    padding = 1,
                    ttl = 5 * 60,
                    indent = 3,
                },
                -- { section = "startup" },
            },
        },
        notifier = {
            enabled = true,
            timeout = 3000,
        },
        quickfile = { enabled = true },
        statuscolumn = { enabled = true },
        input = { enabled = true },
        image = {
            doc = {
                enabled = true,
                inline = false,
                hover = true,
            },
        },
        scroll = { enabled = false },
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
                frecency = true,
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
                    -- filename_first = true,
                },
            },
            file = {
                max_size = 10 * 1024 * 1024,
                max_line_length = 5000,
            },
            previewers = {
                git = {
                    native = true,
                },
            },
            layout = {
                cycle = true,
                preset = "ivy",
                -- preset = function()
                --     return vim.o.columns >= 140 and "ivy" or "default"
                -- end,
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
                        ["<A-s>"] = { "flash", mode = { "n", "i" } },
                        ["s"] = { "flash" },
                    },
                },
            },
            actions = {
                flash = function(picker)
                    require("flash").jump {
                        pattern = "^",
                        label = { after = { 0, 0 } },
                        search = {
                            mode = "search",
                            exclude = {
                                function(win)
                                    return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                                end,
                            },
                        },
                        action = function(match)
                            local idx = picker.list:row2idx(match.pos[1])
                            picker.list:_move(idx, true, true)
                        end,
                    }
                end,
            },
        },
    }
    vim.keymap.set("n", "<leader>n", function()
        Snacks.notifier.hide()
    end, { desc = "Dismiss All Notifications", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Gw", function()
        Snacks.gitbrowse()
    end, { desc = "Git Browse", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Go", function()
        Snacks.picker.git_status()
    end, { desc = "Open changed file", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>GL", function()
        Snacks.lazygit()
    end, { desc = "Lazygit", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Gf", function()
        Snacks.lazygit.log_file()
    end, { desc = "Log file", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>t", function()
        Snacks.terminal()
    end, { desc = "Terminal", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>b", function()
        Snacks.picker.buffers()
    end, { desc = "Buffers", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Fp", function()
        Snacks.picker()
    end, { desc = "Pickers", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Ff", function()
        Snacks.picker.files { hidden = true }
    end, { desc = "Files", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Ft", function()
        Snacks.picker.grep()
    end, { desc = "Text", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Fl", function()
        Snacks.picker.lines()
    end, { desc = "Line", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Fc", function()
        Snacks.picker.colorschemes()
    end, { desc = "Colorscheme", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Fh", function()
        Snacks.picker.help()
    end, { desc = "Find Help", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Fk", function()
        Snacks.picker.keymaps()
    end, { desc = "Keymaps", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Fr", function()
        Snacks.picker.recent()
    end, { desc = "Recent File", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>FM", function()
        Snacks.picker.man()
    end, { desc = "Man Pages", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>FR", function()
        Snacks.picker.registers()
    end, { desc = "Registers", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>FC", function()
        Snacks.picker.commands()
    end, { desc = "Commands", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Fu", function()
        Snacks.picker.undo()
    end, { desc = "Undo", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>FT", function()
        require("config.snacks.pickers.tabs").tabs_picker()
    end, { desc = "Tabs", noremap = true, silent = true })
    vim.keymap.set("n", '<leader>F"', function()
        Snacks.picker.registers()
    end, { desc = "Registers", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>e", function()
        Snacks.picker.explorer { hidden = true }
    end, { desc = "Explorer", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>Fw", function()
        Snacks.picker.grep_word()
    end, { desc = "Word", noremap = true, silent = true })
    vim.keymap.set("n", "<localleader>s", function()
        Snacks.scratch()
    end, { desc = "Scratch Toggle", noremap = true, silent = true })
    vim.keymap.set("n", "<localleader>l", function()
        Snacks.scratch.select()
    end, { desc = "Scratch Select", noremap = true, silent = true })
    vim.keymap.set("n", "<localleader>N", function()
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
    end, { desc = "Neovim News", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>GHi", function()
        Snacks.picker.gh_issue()
    end, { desc = "GitHub Issues (open)" })
    vim.keymap.set("n", "<leader>GI", function()
        Snacks.picker.gh_issue { state = "all" }
    end, { desc = "GitHub Issues (all)" })
    vim.keymap.set("n", "<leader>GHp", function()
        Snacks.picker.gh_pr()
    end, { desc = "GitHub Pull Requests (open)" })
    vim.keymap.set("n", "<leader>GHP", function()
        Snacks.picker.gh_pr { state = "all" }
    end, { desc = "GitHub Pull Requests (all)" })
end)
