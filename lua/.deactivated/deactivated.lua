return {
	{
		"nvim-orgmode/orgmode",
		enabled = false,
		dependencies = {
			"chipsenkbeil/org-roam.nvim",
			config = function()
				require("org-roam").setup({
					directory = "~/Dropbox/org/pages/",
					bindings = {
						prefix = "<leader><leader>on",
					},
					extensions = {
						dailies = {
							directory = "~/Dropbox/org/journals/",
						},
					},
				})
			end,
		},
		event = "VeryLazy",
		config = function()
			-- Setup orgmode
			require("orgmode").setup({
				org_agenda_files = "~/Dropbox/org/**/*",
				org_todo_keywords = { "TODO", "DOING", "|", "DONE", "CANCELLED" },
				org_hide_leading_stars = true,
				org_log_done = "time",
				mappings = {
					prefix = "<leader><leader>o",
				},
			})
		end,
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
			{ "<leader>NT", "<cmd>Neorg cycle_task<CR>", desc = "Cycle task" },
			{ "<leader>N_", "<cmd>Neorg update_property_metadata<CR>", desc = "Update property metadata" },
			{ "<leader>NFB", "<cmd>Neorg roam backlinks<cr>", desc = "Backlinks" },
			{ "<leader>Nw", "<cmd>Neorg roam select_workspace<cr>", desc = "Workspaces" },
			{ "<leader>NFb", "<cmd>Neorg roam block<cr>", desc = "Block Injector" },
			{ "<leader>NFn", "<cmd>Neorg roam node<cr>", desc = "Node Injector" },
			{ "<leader>NAd", "<cmd>Neorg agenda day<cr>", desc = "Neorg Agenda Day" },
			{ "<leader>NAp", "<cmd>Neorg agenda page undone pending hold<cr>", desc = "Neorg Agenda Page" },
			{ "<leader>NAt", "<cmd>Neorg agenda tag<cr>", desc = "Neorg Agenda Tag" },
			{ "<leader>Nt", "<cmd>Neorg toc<cr>", desc = "Table of Contents" },
			{ "<leader>Ni", "<cmd>Neorg index<cr>", desc = "Index" },
			{ "<leader>NJt", "<cmd>Neorg journal today<cr>", desc = "Today's Journal" },
			{ "<leader>NJm", "<cmd>Neorg journal tomorrow<cr>", desc = "Tomorrow's Journal" },
			{ "<leader>NJy", "<cmd>Neorg journal yesterday<cr>", desc = "Yesterday's Journal" },
			{ "<leader>NMi", "<cmd>Neorg inject-metadata<cr>", desc = "Inject" },
			{ "<leader>NMu", "<cmd>Neorg update-metadata<cr>", desc = "Update" },
		},
		config = function()
			require("neorg").setup({
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
			})

			require("neorg.core").modules.get_module("core.dirman").set_workspace("default")
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
					require("image").setup({
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
						window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
						window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
						editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
						tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
						hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
					})
				end,
			},
		},
		config = function()
			require("diagram").setup({ -- you can just pass {}, defaults below
				integrations = {
					require("diagram.integrations.neorg"),
				},
				renderer_options = {
					mermaid = {
						background = nil, -- nil | "transparent" | "white" | "#hex"
						theme = nil, -- nil | "default" | "dark" | "forest" | "neutral"
						scale = 1, -- nil | 1 (default) | 2  | 3 | ...
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
			})
		end,
	},
}
