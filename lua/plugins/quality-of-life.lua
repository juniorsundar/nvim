return {
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"<C-s>",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"<C-S-s>",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"r",
				mode = "o",
				function()
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "o", "x" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Tresitter Search",
			},
			{
				"<C-s>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "VeryLazy",
		opts = {
			indent = {
				char = "╎",
				tab_char = "╎",
			},
			scope = { enabled = false },
			exclude = {
				filetypes = {
					"help",
					"alpha",
					"dashboard",
					"neo-tree",
					"Trouble",
					"trouble",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"lazyterm",
					"norg",
					"git",
					"fugitive",
				},
			},
		},
		main = "ibl",
	},
	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
	},
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end,
	},
	{
		"3rd/image.nvim",
		ft = { "markdown", "norg" },
        dependencies = { "luarocks.nvim" },
		config = function()
			require("image").setup({
				backend = "kitty",
				integrations = {
					markdown = {
						enabled = true,
						clear_in_insert_mode = false,
						download_remote_images = true,
						only_render_image_at_cursor = false,
						filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
					},
					neorg = {
						enabled = true,
						clear_in_insert_mode = false,
						download_remote_images = true,
						only_render_image_at_cursor = false,
						filetypes = { "norg" },
					},
				},
				max_width = nil,
				max_height = nil,
				max_width_window_percentage = nil,
				max_height_window_percentage = 50,
				window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
				window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
				editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
				tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
				hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
			})
		end,
	},
	{
		"MagicDuck/grug-far.nvim",
		config = function()
			local opts = {
				-- debounce milliseconds for issuing search while user is typing
				-- prevents excesive searching
				debounceMs = 500,

				-- minimum number of chars which will cause a search to happen
				-- prevents performance issues in larger dirs
				minSearchChars = 2,

				-- max number of parallel replacements tasks
				maxWorkers = 4,

				-- ripgrep executable to use, can be a different path if you need to configure
				rgPath = "rg",

				-- extra args that you always want to pass to rg
				-- like for example if you always want context lines around matches
				extraRgArgs = "",

				-- specifies the command to run (with `vim.cmd(...)`) in order to create
				-- the window in which the grug-far buffer will appear
				-- ex (horizontal bottom right split): 'botright split'
				-- ex (open new tab): 'tabnew'
				windowCreationCommand = "tabnew",

				-- buffer line numbers + match line numbers can get a bit visually overwhelming
				-- turn this off if you still like to see the line numbers
				disableBufferLineNumbers = true,

				-- maximum number of search chars to show in buffer and quickfix list titles
				-- zero disables showing it
				maxSearchCharsInTitles = 30,

				-- whether to start in insert mode,
				-- set to false for normal mode
				startInInsertMode = true,

				-- row in the window to position the cursor at at start
				startCursorRow = 3,

				-- shortcuts for the actions you see at the top of the buffer
				-- set to '' or false to unset. Mappings with no normal mode value will be removed from the help header
				-- you can specify either a string which is then used as the mapping for both normmal and insert mode
				-- or you can specify a table of the form { [mode] = <lhs> } (ex: { i = '<C-enter>', n = '<localleader>gr'})
				-- it is recommended to use <localleader> though as that is more vim-ish
				-- see https://learnvimscriptthehardway.stevelosh.com/chapters/11.html#local-leader
				keymaps = {
					replace = { n = "<localleader>r" },
					qflist = { n = "<localleader>q" },
					syncLocations = { n = "<localleader>s" },
					syncLine = { n = "<localleader>l" },
					close = { n = "<localleader>c" },
					historyOpen = { n = "<localleader>t" },
					historyAdd = { n = "<localleader>a" },
					refresh = { n = "<localleader>f" },
					gotoLocation = { n = "<enter>" },
					pickHistoryEntry = { n = "<enter>" },
				},

				-- separator between inputs and results, default depends on nerdfont
				resultsSeparatorLineChar = "",

				-- spinner states, default depends on nerdfont, set to false to disable
				spinnerStates = {
					"󱑋 ",
					"󱑌 ",
					"󱑍 ",
					"󱑎 ",
					"󱑏 ",
					"󱑐 ",
					"󱑑 ",
					"󱑒 ",
					"󱑓 ",
					"󱑔 ",
					"󱑕 ",
					"󱑖 ",
				},

				-- whether to report duration of replace/sync operations
				reportDuration = true,

				-- maximum width of help header
				headerMaxWidth = 100,

				-- icons for UI, default ones depend on nerdfont
				-- set individul ones to '' to disable, or set enabled = false for complete disable
				icons = {
					-- whether to show icons
					enabled = true,

					actionEntryBullet = "󰐊 ",

					searchInput = " ",
					replaceInput = " ",
					filesFilterInput = " ",
					flagsInput = "󰮚 ",

					resultsStatusReady = "󱩾 ",
					resultsStatusError = " ",
					resultsStatusSuccess = "󰗡 ",
					resultsActionMessage = "  ",
					resultsChangeIndicator = "┃",

					historyTitle = "  ",
				},

				-- placeholders to show in input areas when they are empty
				-- set individul ones to '' to disable, or set enabled = false for complete disable
				placeholders = {
					-- whether to show placeholders
					enabled = true,

					search = "ex: foo    foo([a-z0-9]*)    fun\\(",
					replacement = "ex: bar    ${1}_foo    $$MY_ENV_VAR ",
					filesFilter = "ex: *.lua     *.{css,js}    **/docs/*.md",
					flags = "ex: --help --ignore-case (-i) <relative-file-path> --replace= (empty replace) --multiline (-U)",
				},

				-- strings to auto-fill in each input area at start
				-- those are not necessarily useful as global defaults but quite useful as overrides
				-- when lauching through the lua api. For example, this is how you would lauch grug-far.nvim
				-- with the current word under the cursor as the search string
				--
				-- require('grug-far').grug_far({ prefills = { search = vim.fn.expand("<cword>") } })
				--
				prefills = {
					search = "",
					replacement = "",
					filesFilter = "",
					flags = "",
				},

				-- search history settings
				history = {
					-- maximum number of lines in history file, end of file will be smartly truncated
					-- to remove oldest entries
					maxHistoryLines = 10000,

					-- directory where to store history file
					historyDir = vim.fn.stdpath("state") .. "/grug-far",

					-- configuration for when to auto-save history entries
					autoSave = {
						-- whether to auto-save at all, trumps all other settings below
						enabled = true,

						-- auto-save after a replace
						onReplace = true,

						-- auto-save after sync all
						onSyncAll = true,

						-- auto-save after buffer is deleted
						onBufDelete = true,
					},
				},
			}
			require("grug-far").setup(opts)
		end,
	},
}
