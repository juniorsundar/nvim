MiniDeps.now(function()
	MiniDeps.add({ source = "catppuccin/nvim", name = "catppuccin" })

	local doom = {
		crust = "#1b2229",
		mantle = "#21242b",
		base = "#282c34",
		surface0 = "#3f444a",
		surface1 = "#5b6268",
		surface2 = "#73797e",
		overlay0 = "#3f444a",
		overlay1 = "#5b6268",
		overlay2 = "#9ca0a4",
		subtext0 = "#73797e",
		subtext1 = "#9ca0a4",
		text = "#bbc2cf",
		red = "#ff6c6b",
		peach = "#da8548",
		yellow = "#ecbe7b",
		green = "#98be65",
		teal = "#4db5bd",
		sky = "#46d9ff",
		sapphire = "#5699af",
		blue = "#51afef",
		lavender = "#a9a1e1",
		mauve = "#c678dd",
		pink = "#c678dd",
		maroon = nil,
		flamingo = nil,
		rosewater = nil,
	}
	local config = {
		color_overrides = {
			macchiato = doom,
		},
		custom_highlights = function(colors)
			return {}
		end,
		highlight_overrides = {
			macchiato = function(colors)
				return {
					NormalFloat = { fg = colors.text, bg = colors.base },
					LineNr = { fg = colors.overlay1 },
					CursorLineNr = { fg = colors.text },
					Comment = { fg = colors.overlay1 },
					WhichKey = { fg = colors.blue, bg = nil },
					WhichKeyNormal = { fg = colors.text, bg = nil },
					WhichKeyDesc = { fg = colors.maroon },
					Folded = { fg = colors.crust, bg = colors.none },
					BlinkCmpMenu = { fg = colors.text, bg = colors.base },
					BlinkCmpMenuBorder = { fg = colors.text, bg = colors.base },
				}
			end,
		},
		transparent_background = false,
		float = {
			transparent = true,
		},
		auto_integrations = true,
	}
	require("catppuccin").setup(config)
	vim.cmd.colorscheme("catppuccin-macchiato")
end)
