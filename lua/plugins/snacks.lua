return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        bigfile = { enabled = true },
        dashboard = {
            enabled = true,
            preset = {
                keys = {
                    { icon = " ", key = "f", desc = "Find File", action = function() Snacks.picker.files({ hidden = true }) end },
                    { icon = " ", key = "n", desc = "New File", action = function() vim.cmd(":ene | startinsert") end },
                    { icon = " ", key = "t", desc = "Find Text", action = function() Snacks.dashboard.pick('live_grep') end },
                    { icon = " ", key = "r", desc = "Recent Files", action = function() Snacks.dashboard.pick('oldfiles') end },
                    { icon = " ", key = "c", desc = "Config", action = function() Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')}) end },
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
                    -- filename_first = true,
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
        { "<leader>n",      function() Snacks.notifier.hide() end,                    desc = "Dismiss All Notifications" },
        { "<leader>Gw",     function() Snacks.gitbrowse() end,                        desc = "Git Browse" },
        { "<leader>Go",     function() Snacks.picker.git_status() end,                desc = "Open changed file" },
        { "<leader>GL",     function() Snacks.lazygit() end,                          desc = "Lazygit" },
        { "<leader>Gf",     function() Snacks.lazygit.log_file() end,                 desc = "Log file" },
        { "<leader>t",      function() Snacks.terminal() end,                         desc = "Terminal" },
        { "<leader>b",      function() Snacks.picker.buffers() end,                   desc = "Buffers" },
        { "<leader>Fp",     function() Snacks.picker() end,                           desc = "Pickers" },
        { "<leader>Ff",     function() Snacks.picker.files({ hidden = true }) end,    desc = "Files" },
        { "<leader>Ft",     function() Snacks.picker.grep() end,                      desc = "Text" },
        { "<leader>Fl",     function() Snacks.picker.lines() end,                     desc = "Line" },
        { "<leader>Fc",     function() Snacks.picker.colorschemes() end,              desc = "Colorscheme" },
        { "<leader>Fh",     function() Snacks.picker.help() end,                      desc = "Find Help" },
        { "<leader>Fk",     function() Snacks.picker.keymaps() end,                   desc = "Keymaps" },
        { "<leader>Fr",     function() Snacks.picker.recent() end,                    desc = "Recent File" },
        { "<leader>FM",     function() Snacks.picker.man() end,                       desc = "Man Pages" },
        { "<leader>FR",     function() Snacks.picker.registers() end,                 desc = "Registers" },
        { "<leader>FC",     function() Snacks.picker.commands() end,                  desc = "Commands" },
        { "<leader>Fu",     function() Snacks.picker.undo() end,                      desc = "Undo" },
        { "<leader>Fe",     function() Snacks.picker.explorer({ hidden = true }) end, desc = "Explorer" },
        { "<leader>Fw",     function() Snacks.picker.grep_word() end,                 desc = "Word" },
        { "<leader>Lr",     function() Snacks.picker.lsp_references() end,            desc = "References" },
        { "<leader>Lt",     function() Snacks.picker.lsp_type_definitions() end,      desc = "Type Definition" },
        { "<leader>LDs",    function() Snacks.picker.lsp_symbols() end,               desc = "Document Symbols" },
        { "<leader>LDd",    function() Snacks.picker.diagnostics_buffer() end,        desc = "Document Diagnostics" },
        { "<leader>LWs",    function() Snacks.picker.lsp_workspace_symbols() end,     desc = "Workspace Symbols" },
        { "<leader>LWd",    function() Snacks.picker.diagnostics() end,               desc = "Workspace Diagnostics" },
        { "<localleader>s", function() Snacks.scratch() end,                          desc = "Scratch Toggle" },
        { "<localleader>l", function() Snacks.scratch.select() end,                   desc = "Scratch Select" },
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
                Snacks.toggle.inlay_hints():map("<leader>Lh")
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
}
