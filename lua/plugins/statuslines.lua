return {
	{
		"rebelot/heirline.nvim",
		dependencies = {
			"Zeioth/heirline-components.nvim",
		},
		opts = {},
		config = function(_, opts)
			local conditions = require("heirline.conditions")
			local utils = require("heirline.utils")
			opts.colors = {
				bright_bg = utils.get_highlight("Folded").bg,
				bright_fg = utils.get_highlight("Folded").fg,
				red = utils.get_highlight("DiagnosticError").fg,
				dark_red = utils.get_highlight("DiffDelete").bg,
				green = utils.get_highlight("String").fg,
				blue = utils.get_highlight("Function").fg,
				gray = utils.get_highlight("NonText").fg,
				orange = utils.get_highlight("Constant").fg,
				purple = utils.get_highlight("Statement").fg,
				cyan = utils.get_highlight("Special").fg,
				diag_warn = utils.get_highlight("DiagnosticWarn").fg,
				diag_error = utils.get_highlight("DiagnosticError").fg,
				diag_hint = utils.get_highlight("DiagnosticHint").fg,
				diag_info = utils.get_highlight("DiagnosticInfo").fg,
				git_del = utils.get_highlight("diffDeleted").fg,
				git_add = utils.get_highlight("diffAdded").fg,
				git_change = utils.get_highlight("diffChanged").fg,
			}
			local FileNameBlock = {
				init = function(self)
					self.filename = vim.api.nvim_buf_get_name(0)
				end,
			}

			local FileName = {
				provider = function(self)
					local filename = vim.fn.fnamemodify(self.filename, ":.")
					if filename == "" then
						return "[No Name]"
					end
					if not conditions.width_percent_below(#filename, 0.25) then
						filename = vim.fn.pathshorten(filename)
					end
					return filename
				end,
				hl = { fg = utils.get_highlight("Directory").fg },
			}

			local FileFlags = {
				{
					condition = function()
						return vim.bo.modified
					end,
					provider = " --> [+]",
					hl = { fg = "orange" },
				},
				{
					condition = function()
						return not vim.bo.modifiable or vim.bo.readonly
					end,
					provider = " --> []",
					hl = { fg = "orange" },
				},
			}

			local FileNameModifer = {
				hl = function()
					if vim.bo.modified then
						return { fg = "orange", bold = true, force = true }
					end
				end,
			}

			FileNameBlock =
				utils.insert(FileNameBlock, utils.insert(FileNameModifer, FileName), FileFlags, { provider = "%<" })

			local TerminalName = {
				provider = function()
					local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
					return " " .. tname
				end,
				hl = { fg = "fg", bold = true },
			}

			local heirline = require("heirline")
			local heirline_components = require("heirline-components.all")

			local DefaultStatusLine = {
				hl = { fg = "fg", bg = "bg" },
				heirline_components.component.mode({ mode_text = {} }),
				heirline_components.component.git_branch(),
				heirline_components.component.diagnostics(),
				FileNameBlock,
				heirline_components.component.fill(),
				heirline_components.component.cmd_info(),
				heirline_components.component.file_info(),
				heirline_components.component.nav(),
				heirline_components.component.mode({ surround = { separator = "right" } }),
			}
			local InactiveStatusline = {
				condition = conditions.is_not_active,
				heirline_components.component.fill(),
				FileNameBlock,
				{ provider = " --> " },
				heirline_components.component.file_info(),
				heirline_components.component.fill(),
			}
			local TerminalStatusline = {
				condition = function()
					return conditions.buffer_matches({ buftype = { "terminal" } })
				end,
				hl = { bg = "bg" },
				{ condition = conditions.is_active, heirline_components.component.mode({ mode_text = {} }) },
				heirline_components.component.fill(),
				TerminalName,
				heirline_components.component.fill(),
				{
					condition = conditions.is_active,
					heirline_components.component.mode({ surround = { separator = "right" } }),
				},
			}
			local ExcludeStatusline = {
				condition = function()
					return conditions.buffer_matches({
						buftype = { "nofile", "prompt", "help", "quickfix" },
						filetype = { "fugitive", "oil", "alpha" },
					})
				end,
			}
			opts.statusline = {
				hl = function()
					if conditions.is_active() then
						return "StatusLine"
					else
						return "StatusLineNC"
					end
				end,
				fallthrough = false,
				ExcludeStatusline,
                TerminalStatusline,
				InactiveStatusline,
				DefaultStatusLine,
			}

			-- Setup
			heirline_components.init.subscribe_to_events()
			heirline.load_colors(heirline_components.hl.get_colors())
			heirline.setup(opts)
		end,
	},
}
