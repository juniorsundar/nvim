MiniDeps.later(function()
    MiniDeps.add { source = "folke/sidekick.nvim" }

    require("sidekick").setup {
        jump = {
            jumplist = true,
        },
        signs = {
            enabled = true,
            icon = " ",
        },
        nes = {
            ---@type boolean|fun(buf:integer):boolean?
            enabled = false,
            debounce = 100,
            trigger = {
                -- events that trigger sidekick next edit suggestions
                events = { "ModeChanged i:n", "TextChanged", "User SidekickNesDone" },
            },
            clear = {
                -- events that clear the current next edit suggestion
                events = { "TextChangedI", "InsertEnter" },
                esc = true, -- clear next edit suggestions when pressing <Esc>
            },
            diff = {
                inline = "words",
            },
        },
        -- Work with AI cli tools directly from within Neovim
        cli = {
            watch = true,
            win = {
                --- This is run when a new terminal is created, before starting it.
                --- Here you can change window options `terminal.opts`.
                config = function(terminal) end,
                bo = {
                    filetype = "snacks_terminal",
                },
                wo = { winhighlight = "" },
                layout = "right", ---@type "float"|"left"|"bottom"|"top"|"right"
                --- Options used when layout is "float"
                float = {
                    width = 0.9,
                    height = 0.9,
                },
                -- Options used when layout is "left"|"bottom"|"top"|"right"
                split = {
                    width = 80, -- set to 0 for default split width
                    height = 20, -- set to 0 for default split height
                },
                --- CLI Tool Keymaps (default mode is `t`)
                keys = {
                    buffers = { "<c-b>", "buffers", mode = "nt", desc = "open buffer picker" },
                    files = { "<c-f>", "files", mode = "nt", desc = "open file picker" },
                    hide_n = { "q", "hide", mode = "n", desc = "hide the terminal window" },
                    hide_ctrl_q = { "<c-q>", "hide", mode = "n", desc = "hide the terminal window" },
                    hide_ctrl_dot = { "<c-.>", "hide", mode = "nt", desc = "hide the terminal window" },
                    hide_ctrl_z = { "<c-z>", "hide", mode = "nt", desc = "hide the terminal window" },
                    prompt = { "<c-p>", "prompt", mode = "t", desc = "insert prompt or context" },
                    stopinsert = { "<c-q>", "stopinsert", mode = "t", desc = "enter normal mode" },
                    -- Navigate windows in terminal mode. Only active when:
                    -- * layout is not "float"
                    -- * there is another window in the direction
                    -- With the default layout of "right", only `<c-h>` will be mapped
                    nav_left = { "<c-h>", "nav_left", expr = true, desc = "navigate to the left window" },
                    nav_down = { "<c-j>", "nav_down", expr = true, desc = "navigate to the below window" },
                    nav_up = { "<c-k>", "nav_up", expr = true, desc = "navigate to the above window" },
                    nav_right = { "<c-l>", "nav_right", expr = true, desc = "navigate to the right window" },
                },
                ---@type fun(dir:"h"|"j"|"k"|"l")?
                --- Function that handles navigation between windows.
                --- Defaults to `vim.cmd.wincmd`. Used by the `nav_*` keymaps.
                nav = nil,
            },
            ---@class sidekick.cli.Mux
            ---@field backend? "tmux"|"zellij" Multiplexer backend to persist CLI sessions
            mux = {
                backend = vim.env.ZELLIJ and "zellij" or "tmux", -- default to tmux unless zellij is detected
                enabled = false,
                -- terminal: new sessions will be created for each CLI tool and shown in a Neovim terminal
                -- window: when run inside a terminal multiplexer, new sessions will be created in a new tab
                -- split: when run inside a terminal multiplexer, new sessions will be created in a new split
                -- NOTE: zellij only supports `terminal`
                create = "terminal", ---@type "terminal"|"window"|"split"
                split = {
                    vertical = true, -- vertical or horizontal split
                    size = 0.5, -- size of the split (0-1 for percentage)
                },
            },
            ---@type table<string, sidekick.cli.Config|{}>
            tools = {
                aider = { cmd = { "aider" } },
                amazon_q = { cmd = { "q" } },
                claude = { cmd = { "claude" } },
                codex = { cmd = { "codex", "--enable", "web_search_request" } },
                copilot = { cmd = { "copilot", "--banner" } },
                crush = {
                    cmd = { "crush" },
                    -- crush uses <a-p> for its own functionality, so we override the default
                    keys = { prompt = { "<a-p>", "prompt" } },
                },
                cursor = { cmd = { "cursor-agent" } },
                gemini = { cmd = { "gemini" } },
                grok = { cmd = { "grok" } },
                opencode = {
                    cmd = { "opencode" },
                    -- HACK: https://github.com/sst/opencode/issues/445
                    env = { OPENCODE_THEME = "system" },
                },
                qwen = { cmd = { "qwen" } },
            },
            --- Add custom context. See `lua/sidekick/context/init.lua`
            context = {},
            prompts = {
                changes = "Can you review my changes?",
                diagnostics = "Can you help me fix the diagnostics in {file}?\n{diagnostics}",
                diagnostics_all = "Can you help me fix these diagnostics?\n{diagnostics_all}",
                document = "Add documentation to {function|line}",
                explain = "Explain {this}",
                fix = "Can you fix {this}?",
                optimize = "How can {this} be optimized?",
                review = "Can you review {file} for any issues or improvements?",
                tests = "Can you write tests for {this}?",
                -- simple context prompts
                buffers = "{buffers}",
                file = "{file}",
                line = "{line}",
                position = "{position}",
                quickfix = "{quickfix}",
                selection = "{selection}",
                ["function"] = "{function}",
                class = "{class}",
            },
            -- preferred picker for selecting files
            picker = "snacks",
        },
        copilot = {
            -- track copilot's status with `didChangeStatus`
            status = {
                enabled = true,
                level = vim.log.levels.WARN,
                -- set to vim.log.levels.OFF to disable notifications
                -- level = vim.log.levels.OFF,
            },
        },
        ui = {
            icons = {
                attached = " ",
                started = " ",
                installed = " ",
                missing = " ",
                external_attached = "󰖩 ",
                external_started = "󰖪 ",
                terminal_attached = " ",
                terminal_started = " ",
            },
        },
        debug = false, -- enable debug logging
    }

    vim.keymap.set({ "n", "x" }, "<leader>A", "", { desc = "Sidekick" })

    vim.keymap.set({ "n", "t", "i", "x" }, "<c-.>", function()
        require("sidekick.cli").toggle()
    end, { desc = "Sidekick Toggle" })

    vim.keymap.set("n", "<leader>Aa", function()
        require("sidekick.cli").toggle()
    end, { desc = "Sidekick Toggle CLI" })

    vim.keymap.set("n", "<leader>As", function()
        require("sidekick.cli").select()
    end, { desc = "Select CLI" })

    vim.keymap.set("n", "<leader>Ad", function()
        require("sidekick.cli").close()
    end, { desc = "Detach a CLI Session" })

    vim.keymap.set({ "x", "n" }, "<leader>At", function()
        require("sidekick.cli").send { msg = "{this}" }
    end, { desc = "Send This" })

    vim.keymap.set("n", "<leader>Af", function()
        require("sidekick.cli").send { msg = "{file}" }
    end, { desc = "Send File" })

    vim.keymap.set("x", "<leader>Av", function()
        require("sidekick.cli").send { msg = "{selection}" }
    end, { desc = "Send Visual Selection" })

    vim.keymap.set({ "n", "x" }, "<leader>Ap", function()
        require("sidekick.cli").prompt()
    end, { desc = "Sidekick Select Prompt" })
    -- "<leader>Ac",
    -- function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
    -- desc = "Sidekick Toggle Claude",
end)
