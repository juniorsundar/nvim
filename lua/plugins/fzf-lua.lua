return {
	{
		"ibhagwan/fzf-lua",
		-- optional for icon support
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			-- calling `setup` is optional for customization
			require("fzf-lua").setup({
				winopts = {
					preview = {
						vertical = "up:65%", -- up|down:size
						layout = "vertical", -- horizontal|vertical|flex
						delay = 10,
					},
				},
			})
			require("fzf-lua").register_ui_select()
		end,
	},
}
