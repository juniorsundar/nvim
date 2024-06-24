return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 500
	end,
	config = function()
		local keymap = vim.keymap -- for conciseness
		local status_ok, which_key = pcall(require, "which-key")
		if not status_ok then
			return
		end

		local setup = {
			plugins = {
				marks = true, -- shows a list of your marks on ' and `
				registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
				spelling = {
					enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
					suggestions = 20, -- how many suggestions should be shown in the list?
				},
				presets = {
					operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
					motions = true, -- adds help for motions
					text_objects = true, -- help for text objects triggered after entering an operator
					windows = true, -- default bindings on <c-w>
					nav = true, -- misc bindings to work with windows
					z = true, -- bindings for folds, spelling and others prefixed with z
					g = true, -- bindings for prefixed with g
				},
			},
			key_labels = {
				-- Custom labels for keys
			},
			icons = {
				breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
				separator = "➜", -- symbol used between a key and its label
				group = "+", -- symbol prepended to a group
			},
			popup_mappings = {
				scroll_down = "<c-d>", -- binding to scroll down inside the popup
				scroll_up = "<c-u>", -- binding to scroll up inside the popup
			},
			window = {
				border = "rounded", -- none, single, double, shadow
				position = "bottom", -- bottom, top
				margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
				padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
				winblend = 0,
			},
			layout = {
				height = { min = 4, max = 25 }, -- min and max height of the columns
				width = { min = 20, max = 50 }, -- min and max width of the columns
				spacing = 3, -- spacing between columns
				align = "center", -- align columns left, center or right
			},
			ignore_missing = false, -- enable this to hide mappings for which you didn't specify a label
			hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
			show_help = true, -- show help message on the command line when the popup is visible
			triggers = "auto", -- automatically setup triggers
			triggers_blacklist = {
				i = { "j", "k" },
				v = { "j", "k" },
			},
		}

		local opts = {
			mode = "n", -- NORMAL mode
			prefix = "<leader>",
			buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
			silent = true, -- use `silent` when creating keymaps
			noremap = true, -- use `noremap` when creating keymaps
			nowait = true, -- use `nowait` when creating keymaps
		}

		local function list_workspace_folders()
			local folders = vim.lsp.buf.list_workspace_folders()
			if not folders or vim.tbl_isempty(folders) then
				print("No workspace folders found")
				return
			end

			local qf_list = {}
			for _, folder in ipairs(folders) do
				table.insert(qf_list, { filename = folder, lnum = 1, col = 1, text = folder })
			end

			vim.fn.setqflist(qf_list, "r")
			vim.cmd("copen")
		end

		local mappings = {
			a = { "<cmd>Alpha<cr>", "Alpha" },
			w = { "<cmd>w!<cr>", "Save" },
			q = { "<cmd>q<cr>", "Quit" },
			l = { "<cmd>Lazy<cr>", "Lazy" },
			m = { "<cmd>Mason<cr>", "Mason" },
			o = { "<cmd>Oil<cr>", "Oil" },
			t = { "<cmd>terminal<cr>", "Terminal" },
			u = { "<cmd>UndotreeToggle<cr>", "Undotree" },
			c = { "<cmd>bdelete<cr>", "Close Buffer" },
			b = { "<cmd>FzfLua buffers<cr>", "Buffers" },
            ["/"] = { "<cmd>GrugFar<cr>", "GrugFar" },
			-- Autocompletion
			A = {
				name = "Autocompletion",
				e = { "<cmd>lua require 'cmp'.setup{ enabled = true }<cr>", "Enabled" },
				d = { "<cmd>lua require 'cmp'.setup{ enabled = false }<cr>", "Disabled" },
			},
			-- Find
			F = {
				name = "Find",
				f = { "<cmd>FzfLua files<cr>", "Files" },
				t = { "<cmd>FzfLua live_grep<CR>", "Text" },
				c = { "<cmd>FzfLua colorschemes<cr>", "Colorscheme" },
				h = { "<cmd>FzfLua helptags<cr>", "Find Help" },
				k = { "<cmd>FzfLua keymaps<cr>", "Keymaps" },
				r = { "<cmd>FzfLua oldfiles<cr>", "Open Recent File" },
				T = { "<cmd>FzfLua tabs<cr>", "Tabs" },
				M = { "<cmd>FzfLua manpages<cr>", "Man Pages" },
				R = { "<cmd>FzfLua registers<cr>", "Registers" },
				C = { "<cmd>FzfLua commands<cr>", "Commands" },
			},
			-- Git
			G = {
				name = "Git",
				o = { "<cmd>FzfLua git_status<cr>", "Open changed file" },
				b = { "<cmd>FzfLua git_branches<cr>", "Checkout branch" },
				d = { "<cmd>Gitsigns diffthis HEAD<cr>", "Diff" },
			},
			-- Language Server Protocol (LSP)
			L = {
				name = "LSP",
				-- a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code Action" },
				a = { "<cmd>Lspsaga code_action<cr>", "Code Action" },
				f = { "<cmd>lua vim.lsp.buf.format{async=true}<cr>", "Format" },
				l = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action" },
				n = { "<cmd>Lspsaga rename<cr>", "Rename" },
				-- r = { "<cmd>lua vim.lsp.buf.references()<cr>", "References" },
				r = { "<cmd>Lspsaga finder ref ++normal<cr>", "References" },
				-- d = { "<cmd>lua vim.lsp.buf.definition()<cr>", "Definition" },
				-- c = { "<cmd>lua vim.lsp.buf.declaration()<cr>", "Declaration" },
				-- i = { "<cmd>lua vim.lsp.buf.implementation()<cr>", "Implementation" },
				-- k = { "<cmd>lua vim.lsp.buf.hover()<cr>", "Hover" },
				k = { "<cmd>Lspsaga hover_doc<cr>", "Hover" },
				-- t = { "<cmd>lua vim.lsp.buf.goto_type_definition<cr>", "Type Definition" },
				t = { "<cmd>Lspsaga finder tyd ++normal<cr>", "Type Definition" },
				h = { "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>", "Type Hint" },
				o = { "<cmd>Lspsaga outline<cr>", "Outline" },
				I = { "<cmd>LspInfo<cr>", "LSP Info" },
				D = {
					name = "Document",
					-- d = { "<cmd>FzfLua diagnostics_document<cr>", "Document Diagnostics" },
					d = { "<cmd>Lspsaga show_buf_diagnostics ++normal<cr>", "Document Diagnostics" },
					s = { "<cmd>FzfLua lsp_document_symbols<cr>", "Document Symbols" },
					-- j = { "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", "Next Diagnostic" },
					j = { "<cmd>Lspsaga diagnostic_jump_next<CR>", "Next Diagnostic" },
					-- k = { "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>", "Prev Diagnostic" },
					k = { "<cmd>Lspsaga diagnostic_jump_prev<cr>", "Prev Diagnostic" },
				},
				W = {
					name = "Workspace",
					a = { "<cmd>lua vim.lsp.buf.add_workspace_folder()<cr>", "Add Workspace Folder" },
					-- d = { "<cmd>FzfLua diagnostics_workspace<cr>", "Workspace Diagnostics" },
					d = { "<cmd>Lspsaga show_workspace_diagnostics ++normal<cr>", "Workspace Diagnostics" },
					s = { "<cmd>FzfLua lsp_workspace_symbols<cr>", "Workspace Symbols" },
					r = { "<cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>", "Remove Workspace Folder" },
					l = { list_workspace_folders, "List Workspace Folders" },
				},
			},

			N = {
				name = "Neorg",
				i = { "<cmd>Neorg index<cr>", "Index" },
				J = {
					name = "Journal",
					t = { "<cmd>Neorg journal today<cr>", "Today's Journal" },
					m = { "<cmd>Neorg journal tomorrow<cr>", "Tomorrow's Journal" },
					y = { "<cmd>Neorg journal yesterday<cr>", "Yesterday's Journal" },
				},
				M = {
					name = "Metadata",
					i = { "<cmd>Neorg inject-metadata<cr>", "Inject" },
					u = { "<cmd>Neorg update-metadata<cr>", "Update" },
				},
			},
		}

		which_key.setup(setup)
		which_key.register(mappings, opts)
	end,
}
