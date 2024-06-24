return {
    {
        "lewis6991/gitsigns.nvim",
        event = "VeryLazy",
        dependencies = { "sindrets/diffview.nvim" },
        config = function()
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
                    border = "single",
                    style = "minimal",
                    relative = "cursor",
                    row = 0,
                    col = 1,
                },
                yadm = {
                    enable = false,
                },
            })

            vim.keymap.set(
                "n",
                "<space>G]",
                "<cmd>lua require 'gitsigns'.next_hunk()<cr>",
                { noremap = true, silent = false, desc = "Next Hunk" }
            )
            vim.keymap.set(
                "n",
                "<space>G[",
                "<cmd>lua require 'gitsigns'.prev_hunk()<cr>",
                { noremap = true, silent = false, desc = "Previous Hunk" }
            )
            vim.keymap.set(
                "n",
                "<space>Gp",
                "<cmd>lua require 'gitsigns'.preview_hunk()<cr>",
                { noremap = true, silent = false, desc = "Preview Hunk" }
            )
            vim.keymap.set(
                "n",
                "<space>Gr",
                "<cmd>lua require 'gitsigns'.reset_hunk()<cr>",
                { noremap = true, silent = false, desc = "Reset Hunk" }
            )
            vim.keymap.set(
                "n",
                "<space>Gs",
                "<cmd>lua require 'gitsigns'.stage_hunk()<cr>",
                { noremap = true, silent = false, desc = "Stage Hunk" }
            )
            vim.keymap.set(
                "n",
                "<space>Gu",
                "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>",
                { noremap = true, silent = false, desc = "Undo Stage Hunk" }
            )
            vim.keymap.set(
                "n",
                "<space>GR",
                "<cmd>lua require 'gitsigns'.reset_buffer()<cr>",
                { noremap = true, silent = false, desc = "Reset Buffer" }
            )
            vim.keymap.set(
                "n",
                "<space>GB",
                "<cmd>lua require 'gitsigns'.blame_line()<cr>",
                { noremap = true, silent = false, desc = "Blame" }
            )
        end,
    },
    {
    	"NeogitOrg/neogit",
        keys = {
            {"<space>Gg", "<cmd>Neogit<cr>", desc = "Neogit" }
        },
    	branch = "master",
    	dependencies = {
    		"nvim-lua/plenary.nvim", -- required
    		"sindrets/diffview.nvim", -- optional - Diff integration
    	},
    	config = function()
    		local neogit = require("neogit")
    		neogit.setup({
                disable_hint = true,
                graph_style = "unicode",
                kind = "tab",
    			disable_signs = false,
    			signs = {
    				hunk = { "", "" },
    				item = { "", "" },
    				section = { "", "" },
    			},
    			integrations = {
    				diffview = true,
    				fzf_lua = true,
    			},
    		})

    		-- vim.keymap.set("n", "<space>Gg", "<cmd>Neogit<cr>", { noremap = true, silent = false, desc = "Neogit" })
    		vim.keymap.set("v", "gG", "<cmd>Neogit<cr>", { noremap = true, silent = false, desc = "Neogit" })
    	end,
    },
    -- {
    --     "tpope/vim-fugitive",
    --     keys = {
    --         {"<space>Gg", "<cmd>Git<cr>", desc = "Git" }
    --     },
    --     config = function()
    --         vim.api.nvim_command("autocmd FileType fugitive setlocal nonumber norelativenumber")
    --         vim.api.nvim_command("autocmd FileType git setlocal nonumber norelativenumber")
    --         vim.api.nvim_command("autocmd FileType gitcommit setlocal nonumber norelativenumber")
    --         vim.keymap.set("n", "<space>Gg", "<cmd>Git<cr>", { noremap = true, silent = false, desc = "Fugitive" })
    --         vim.keymap.set("v", "gG", "<cmd>Git<cr>", { noremap = true, silent = false, desc = "Fugitive" })
    --     end,
    -- },
}
