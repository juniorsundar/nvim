MiniDeps.later(function()
    MiniDeps.add({ source = "lewis6991/gitsigns.nvim" })

    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        once = true,
        callback = function()
            vim.keymap.set("n", "<leader>Gd", "<cmd>Gitsigns diffthis HEAD<cr>",
                { desc = "Diff", noremap = false, silent = true })
            vim.keymap.set("n", "<space>G]", "<cmd>lua require('gitsigns').next_hunk()<cr>",
                { desc = "Next Hunk", noremap = false, silent = true })
            vim.keymap.set("n", "<space>G[", "<cmd>lua require('gitsigns').prev_hunk()<cr>",
                { desc = "Previous Hunk", noremap = false, silent = true })
            vim.keymap.set("n", "<space>Gp", "<cmd>lua require('gitsigns').preview_hunk()<cr>",
                { desc = "Preview Hunk", noremap = false, silent = true })
            vim.keymap.set("n", "<space>Gr", "<cmd>lua require('gitsigns').reset_hunk()<cr>",
                { desc = "Reset Hunk", noremap = false, silent = true })
            vim.keymap.set("n", "<space>Gs", "<cmd>lua require('gitsigns').stage_hunk()<cr>",
                { desc = "Stage Hunk", noremap = false, silent = true })
            vim.keymap.set("n", "<space>Gu", "<cmd>lua require('gitsigns').undo_stage_hunk()<cr>",
                { desc = "Undo Stage Hunk", noremap = false, silent = true })
            vim.keymap.set("n", "<space>GR", "<cmd>lua require('gitsigns').reset_buffer()<cr>",
                { desc = "Reset Buffer", noremap = false, silent = true })
            vim.keymap.set("n", "<space>GB", "<cmd>lua require('gitsigns').blame()<cr>",
                { desc = "Blame", noremap = false, silent = true })
            vim.keymap.set("n", "<space>Gl", "<cmd>lua require('gitsigns').blame_line()<cr>",
                { desc = "Blame Line", noremap = false, silent = true })

            require("gitsigns").setup({
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
            })
        end
    })
end)
