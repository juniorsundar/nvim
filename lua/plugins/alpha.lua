-- return {
--     'nvimdev/dashboard-nvim',
--     event = 'VimEnter',
--     config = function()
--         local finders = require('telescope.finders')
--         local pickers = require('telescope.pickers')
--         local make_entry = require('telescope.make_entry')
--         local conf = require('telescope.config').values
--
--         local config_path = vim.env.HOME .. '/.dotfiles,' .. vim.env.HOME .. '/.config/nvim'
--
--         local config_file_list = function()
--             local dirs = vim.split(config_path, ',')
--             local list = {}
--             for _, dir in pairs(dirs) do
--                 local p = io.popen('rg --files --hidden ' .. dir)
--                 for file in p:lines() do
--                     table.insert(list, file)
--                 end
--             end
--             return list
--         end
--
--         local configs = function(opts)
--             opts = opts or {}
--             local results = config_file_list()
--
--             pickers
--                 .new(opts, {
--                     prompt_title = 'find in dotfiles',
--                     results_title = 'Dotfiles',
--                     finder = finders.new_table({
--                         results = results,
--                         entry_maker = make_entry.gen_from_file(opts),
--                     }),
--                     previewer = conf.file_previewer(opts),
--                     sorter = conf.file_sorter(opts),
--                     layout_strategy = "vertical",
--                 })
--                 :find()
--         end
--
--         require('dashboard').setup(
--             {
--                 theme = 'hyper',
--                 config = {
--                     week_header = {
--                         enable = true,
--                     },
--                     project = {
--                         enable = false,
--                     },
--                     disable_move = true,
--                     shortcut = {
--                         {
--                             desc = 'New File',
--                             group = 'Function',
--                             action = 'ene',
--                             key = 'e',
--                         },
--                         {
--                             desc = 'Update',
--                             group = 'Include',
--                             action = 'Lazy update',
--                             key = 'u',
--                         },
--                         {
--                             desc = 'Files',
--                             group = 'Function',
--                             action = 'Telescope find_files layout_strategy=vertical',
--                             key = 'f',
--                         },
--                         {
--                             desc = 'Neovim Config',
--                             group = 'Constant',
--                             action = configs,
--                             key = 'c',
--                         },
--                         {
--                             desc = 'Quit',
--                             group = 'String',
--                             action = 'q!',
--                             key = 'q',
--                         },
--                     },
--                 },
--             }
--         )
--     end,
-- }
return {
	"goolord/alpha-nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local dashboard = require("alpha.themes.dashboard")
		require("alpha.themes.theta").header.val = {
			[[                        ██]],
			[[                        ██]],
			[[                       ████]],
			[[                      ██████]],
			[[                     ███  ███]],
			[[                     ███  ███]],
			[[                    ███    ███]],
			[[                   ███      ███]],
			[[                   ███      ███]],
			[[                  ███        ███]],
			[[                  ███        ███]],
			[[                 ███          ███]],
			[[                ███            ███]],
			[[               ████            ████]],
			[[               ███              ███]],
			[[              ███                ███]],
			[[             ████                ████]],
			[[            ████                  ████]],
			[[           ████                    ████]],
			[[ █      ███████                    ███████      █]],
			[[  ████████████                      ████████████]],
			[[  ████████████                      ████████████]],
			[[  ███████████                        ███████████]],
			[[  ██████████                          ██████████]],
			[[  ██████████                          ██████████]],
			[[     ███████                          ████████]],
			[[       █████                          █████]],
			[[         ████                        ████]],
			[[    █       ███                    ███       █]],
			[[       █        ██              ██        █]],
			[[         ██             ██             ██]],
			[[             ████     ██████     ████]],
			[[                 ████████████████]],
		}

		require("alpha.themes.theta").buttons.val = {
			{ type = "text", val = "Quick links", opts = { hl = "SpecialComment", position = "center" } },
			{ type = "padding", val = 1 },
			dashboard.button("e", "  New file", "<cmd>ene<CR>"),
			dashboard.button("<C-j>", "󰃶  Open Daily Journal", "<cmd>Neorg journal today<CR>"),
			dashboard.button("c", "  Configuration", "<cmd>cd ~/.config/nvim/ <CR>"),
			dashboard.button("u", "  Update plugins", "<cmd>Lazy sync<CR>"),
			dashboard.button("q", "󰅚  Quit", "<cmd>qa<CR>"),
		}
		require("alpha").setup(require("alpha.themes.theta").config)
	end,
}
