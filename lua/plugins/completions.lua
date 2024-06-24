return {
	{
		"hrsh7th/nvim-cmp",
		lazy = true,
		version = false,
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp", lazy = true },
			{ "hrsh7th/cmp-nvim-lsp-signature-help", lazy = true },
			{ "hrsh7th/cmp-path", lazy = true },
			{
				"L3MON4D3/LuaSnip",
				lazy = true,
				dependencies = {
					{ "saadparwaiz1/cmp_luasnip", lazy = true },
					{ "rafamadriz/friendly-snippets", lazy = true },
				},

				build = (function()
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
			},
		},

		config = function()
			local has_words_before = function()
				unpack = unpack or table.unpack
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local WIDE_HEIGHT = 40

			local kind_icons = {
				Text = "",
				Method = "󰆧",
				Function = "󰊕",
				Constructor = "",
				Field = "󰇽",
				Variable = "󰂡",
				Class = "󰠱",
				Interface = "",
				Module = "",
				Property = "󰜢",
				Unit = "",
				Value = "󰎠",
				Enum = "",
				Keyword = "󰌋",
				Snippet = "",
				Color = "󰏘",
				File = "󰈙",
				Reference = "",
				Folder = "󰉋",
				EnumMember = "",
				Constant = "󰏿",
				Struct = "",
				Event = "",
				Operator = "",
				TypeParameter = "󰅲",
				Codeium = "",
			}

			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
                view = {
                    entries = "custom" -- can be "custom", "wildmenu" or "native"
                },
				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = function(entry, vim_item)
						-- vim_item.menu = true and  "    (" .. vim_item.kind .. ")" or ""
						vim_item.menu = true and  "    @" .. entry.source.name .. "" or ""
						-- vim_item.menu = true and "    " or ""
						vim_item.kind = " " .. kind_icons[vim_item.kind] .. " "
						return vim_item
					end,
				},
				snippet = {
					completion = {
						completeopt = "menu,menuone",
					},
					expand = function(args)
						require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
					end,
				},

				window = {
                    documentation = cmp.config.window.bordered({
                        -- winhighlight = "FloatBorder:NormalFloat"
                    }),
                    completion = cmp.config.window.bordered({
                        winhighlight = 'Normal:CmpPmenu,CursorLine:PmenuSel,Search:None'
                    }),
					-- completion = {
					-- 	border = { "", "", "", "", "", "", "", "" },
					-- 	winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
					-- 	scrolloff = 0,
					-- 	col_offset = -3,
					-- 	side_padding = 0,
					-- 	scrollbar = true,
					-- },
					-- documentation = {
					-- 	max_height = math.floor(WIDE_HEIGHT * (WIDE_HEIGHT / vim.o.lines)),
					-- 	max_width = math.floor((WIDE_HEIGHT * 2) * (vim.o.columns / (WIDE_HEIGHT * 2 * 16 / 9))),
					-- 	border = { "", "", "", " ", "", "", "", " " },
					-- 	winhighlight = "FloatBorder:NormalFloat",
					-- },
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
					["<Tab>"] = cmp.mapping(function(fallback)
						-- Hint: if the completion menu is visible select next one
						if cmp.visible() then
							cmp.select_next_item()
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, { "i", "s" }), -- i - insert mode; s - select mode
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{
						name = "nvim_lsp",
						option = {
							markdown_oxide = {
								keyword_pattern = [[\(\k\| \|\/\|#\)\+]],
							},
						},
					},
					{ name = "luasnip" }, -- For luasnip users.
					{ name = "path" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "codeium" },
				}),
			})
		end,
	},
}
