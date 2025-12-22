MiniDeps.add { source = "lewis6991/gitsigns.nvim" }

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    once = true,
    callback = function()
        local gs = require "gitsigns"
        vim.keymap.set("n", "<leader>Gd", function()
            gs.diffthis()
        end, { desc = "Diff", noremap = false, silent = true })
        vim.keymap.set("n", "]c", function()
            if vim.wo.diff then
                vim.cmd.normal { "]c", bang = true }
            else
                gs.nav_hunk("next", { target = "all" })
            end
        end, { desc = "Next Hunk", noremap = false, silent = true })
        vim.keymap.set("n", "[c", function()
            if vim.wo.diff then
                vim.cmd.normal { "[c", bang = true }
            else
                gs.nav_hunk("prev", { target = "all" })
            end
        end, { desc = "Previous Hunk", noremap = false, silent = true })
        vim.keymap.set("n", "<space>Gp", function()
            gs.preview_hunk()
        end, { desc = "Preview Hunk", noremap = false, silent = true })
        vim.keymap.set("n", "<space>Gs", function()
            gs.stage_hunk()
        end, { desc = "Stage Hunk", noremap = false, silent = true })
        vim.keymap.set("n", "<space>Gr", function()
            gs.reset_hunk()
        end, { desc = "Reset Hunk", noremap = false, silent = true })
        vim.keymap.set("n", "<space>GS", function()
            gs.stage_buffer()
        end, { desc = "Stage Buffer", noremap = false, silent = true })
        vim.keymap.set("n", "<space>GR", function()
            gs.reset_buffer()
        end, { desc = "Reset Buffer", noremap = false, silent = true })
        vim.keymap.set("n", "<space>GB", function()
            gs.blame()
        end, { desc = "Blame", noremap = false, silent = true })
        vim.keymap.set("n", "<space>Gl", function()
            gs.blame_line()
        end, { desc = "Blame Line", noremap = false, silent = true })

        require("gitsigns").setup {
            signs = {
                add = { text = "┃" },
                change = { text = "┃" },
                delete = { text = "-", show_count = true }, -- '_'
                topdelete = { text = "", show_count = true }, -- '‾'
                changedelete = { text = "~", show_count = true },
                untracked = { text = "┆" },
            },
            signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
            numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
            linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
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
            status_formatter = nil, -- Use default
            max_file_length = 40000, -- Disable if file is longer than this (in lines)
            preview_config = {
                -- Options passed to nvim_open_win
                border = "solid",
                style = "minimal",
                relative = "cursor",
                row = 0,
                col = 1,
            },
        }
    end,
})
