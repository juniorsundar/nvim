MiniDeps.now(function()
	MiniDeps.add({ source = "nvim-lualine/lualine.nvim", depends = { "catppuccin/nvim" } })
	local lualine = require("lualine")

	local palette = require("catppuccin.palettes").get_palette("macchiato")
	local colors = {
		bg = palette.base,
		fg = palette.text,
		yellow = palette.yellow,
		cyan = palette.sapphire,
		darkblue = palette.blue,
		green = palette.green,
		orange = palette.pink,
		violet = palette.mauve,
		magenta = palette.maroon,
		blue = palette.sky,
		red = palette.red,
	}

	local conditions = {
		buffer_not_empty = function()
			return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
		end,
		hide_in_width = function()
			return vim.fn.winwidth(0) > 80
		end,
		check_git_workspace = function()
			local filepath = vim.fn.expand("%:p:h")
			local gitdir = vim.fn.finddir(".git", filepath .. ";")
			return gitdir and #gitdir > 0 and #gitdir < #filepath
		end,
	}

	-- Config
	local config = {
		options = {
			icons_enabled = true,
			disabled_filetypes = {
				"NeogitStatus",
				"snacks_dashboard",
				"ministarter",
				"fzf",
				"neo-tree",
			},
			component_separators = "",
			section_separators = "",
			theme = "catppuccin",
			-- {
			--     normal = { c = { fg = colors.fg, bg = colors.bg } },
			--     inactive = { c = { fg = colors.fg, bg = colors.bg } },
			-- },
		},
		sections = {
			-- these are to remove the defaults
			lualine_a = {},
			lualine_b = {},
			lualine_y = {},
			lualine_z = {},
			-- These will be filled later
			lualine_c = {},
			lualine_x = {},
		},
		inactive_sections = {
			-- these are to remove the defaults
			lualine_a = {},
			lualine_b = {},
			lualine_y = {},
			lualine_z = {},
			lualine_c = {},
			lualine_x = {},
		},
		extensions = { "oil", "quickfix", "mason", "man", "lazy", "fugitive" },
	}

	local function ins_left(component)
		table.insert(config.sections.lualine_c, component)
	end

	local function ins_right(component)
		table.insert(config.sections.lualine_x, component)
	end

	local function ins_inact_left(component)
		table.insert(config.inactive_sections.lualine_c, component)
	end

	local function ins_inact_right(component)
		table.insert(config.inactive_sections.lualine_x, component)
	end

	local mode_color = {
		n = colors.red,
		i = colors.green,
		v = colors.blue,
		[""] = colors.blue,
		V = colors.blue,
		c = colors.magenta,
		no = colors.red,
		s = colors.orange,
		S = colors.orange,
		[""] = colors.orange,
		ic = colors.yellow,
		R = colors.violet,
		Rv = colors.violet,
		cv = colors.red,
		ce = colors.red,
		r = colors.cyan,
		rm = colors.cyan,
		["r?"] = colors.cyan,
		["!"] = colors.red,
		t = colors.red,
	}

	ins_inact_left({
		function()
			return "▊"
		end,
		color = function()
			return { fg = mode_color[vim.fn.mode()] }
		end,
		padding = { left = 0, right = 1 },
	})
	ins_inact_left({
		"filename",
		path = 1,
		cond = conditions.buffer_not_empty,
		color = { fg = colors.fg, gui = "bold" },
	})
	ins_inact_right({
		function()
			return "▊"
		end,
		color = function()
			return { fg = mode_color[vim.fn.mode()] }
		end,
		padding = { left = 0, right = 1 },
	})

	ins_left({
		function()
			return "▊"
		end,
		color = function()
			return { fg = mode_color[vim.fn.mode()] }
		end,
		padding = { left = 0, right = 1 },
	})
	ins_left({
		"lsp_status",
		icon = "",
		symbols = {
			spinner = { "", "", "", "", "", "" },
			done = "󰓦",
			separator = "",
		},
		ignore_lsp = {},
		show_name = false,
		color = function()
			return { fg = colors.bg, bg = mode_color[vim.fn.mode()] }
		end,
	})
	ins_left({
		"filename",
		path = 1,
		cond = conditions.buffer_not_empty,
		color = { fg = colors.fg, gui = "bold" },
	})
	ins_left({
		"diagnostics",
		sources = { "nvim_diagnostic" },
		symbols = { error = " ", warn = " ", info = " " },
		diagnostics_color = {
			error = { fg = colors.red },
			warn = { fg = colors.yellow },
			info = { fg = colors.cyan },
		},
	})
	ins_left({
		function()
			return "%="
		end,
	})
	ins_right({
		"branch",
		icon = "",
		color = { fg = colors.violet, gui = "bold" },
	})
	ins_right({
		"diff",
		symbols = { added = " ", modified = "󰝤 ", removed = " " },
		diff_color = {
			added = { fg = colors.green },
			modified = { fg = colors.orange },
			removed = { fg = colors.red },
		},
		cond = conditions.hide_in_width,
	})
	ins_right({
		"filetype",
		colored = false,
		icon_only = false,
		color = function()
			return { fg = colors.bg, bg = mode_color[vim.fn.mode()] }
		end,
	})
	ins_right({
		function()
			return "▊"
		end,
		color = function()
			return { fg = mode_color[vim.fn.mode()] }
		end,
		padding = { left = 1 },
	})

	lualine.setup(config)
end)
