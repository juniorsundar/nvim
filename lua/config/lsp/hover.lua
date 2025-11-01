---@type table
vim.lsp.autohover = {
	enabled = false,
	delay = 500,
	layout = "eldoc",
	opts = {
		border = "rounded",
		relative = "editor",
		offset_x = vim.o.columns,
		ratio = 0.1,
	},
}
vim.o.updatetime = vim.lsp.autohover.delay

local lsp_hover_augroup = vim.api.nvim_create_augroup("LspHoverOnHold", { clear = true })
local eldoc_close_augroup = vim.api.nvim_create_augroup("LspEldocAutoClose", { clear = true })

local eldoc_win_id = nil
local eldoc_buf_id = nil

local function close_eldoc_window()
	pcall(vim.api.nvim_win_close, eldoc_win_id, true)
	pcall(vim.api.nvim_buf_delete, eldoc_buf_id, { force = true }, true)
	eldoc_buf_id = nil
	eldoc_win_id = nil
end

vim.api.nvim_create_autocmd({ "CursorMoved" }, {
	group = eldoc_close_augroup,
	callback = function()
		if not eldoc_win_id or not vim.api.nvim_win_is_valid(eldoc_win_id) then
			return
		end
		local current_win = vim.api.nvim_get_current_win()
		if current_win ~= eldoc_win_id then
			close_eldoc_window()
		end
	end,
	desc = "Close LSP eldoc window when cursor moves or context changes",
})

vim.api.nvim_create_autocmd("CursorHold", {
	group = lsp_hover_augroup,
	pattern = "*",
	callback = function()
		if not vim.lsp.autohover then
			return
		end
		if not vim.lsp.autohover.enabled then
			return
		end

		local bufnr = vim.api.nvim_get_current_buf()
		local clients = vim.lsp.get_clients({ bufnr = bufnr })

		---@type boolean
		local has_hover_provider = false
		for _, client in ipairs(clients) do
			if client and client.server_capabilities and client.server_capabilities.hoverProvider then
				has_hover_provider = true
				break
			end
		end

		if not has_hover_provider then
			return
		end

		local handler = function(err, result, _, _)
			if err or not result or not result.contents then
				return
			end

			local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)

			if vim.tbl_isempty(lines) then
				return
			end

			if vim.lsp.autohover.layout == "eldoc" then
				if eldoc_win_id ~= nil or eldoc_buf_id ~= nil then
					return
				end
				eldoc_buf_id = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_buf_set_lines(eldoc_buf_id, 0, 0, false, lines)
				eldoc_win_id = vim.api.nvim_open_win(eldoc_buf_id, false, {
					split = "below",
					win = -1,
					height = math.floor(vim.o.lines * vim.lsp.autohover.opts.ratio),
					style = "minimal",
				})
				vim.api.nvim_buf_set_name(eldoc_buf_id, "[LSP Eldoc]")
				vim.api.nvim_set_option_value("filetype", "markdown", { buf = eldoc_buf_id })
				vim.api.nvim_set_option_value("buftype", "nofile", { buf = eldoc_buf_id })
				vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = eldoc_buf_id })
				vim.api.nvim_set_option_value("modifiable", false, { buf = eldoc_buf_id })
				vim.api.nvim_set_option_value("swapfile", false, { buf = eldoc_buf_id })
				return
			elseif vim.lsp.autohover.layout == "float" then
				vim.lsp.util.open_floating_preview(lines, "markdown", vim.lsp.autohover.opts)
				return
			else
				return
			end
		end

		local params = vim.lsp.util.make_position_params(0, "utf-32")
		vim.lsp.buf_request(bufnr, "textDocument/hover", params, handler)
	end,
	desc = "Show LSP hover documentation on CursorHold (silently ignores empty responses)",
})

local function toggle_auto_hover()
	if vim.lsp.autohover == nil then
		vim.notify("`vim.lsp.autohover` doesn't exists!", vim.log.levels.WARN, { title = "LSP" })
		return
	end
	if vim.lsp.autohover.enabled == nil then
		vim.notify("`vim.lsp.autohover.enabled` doesn't exists!", vim.log.levels.WARN, { title = "LSP" })
		return
	end
	vim.lsp.autohover.enabled = not vim.lsp.autohover.enabled
	if vim.lsp.autohover.enabled then
		vim.notify("Auto Hover enabled", vim.log.levels.INFO, { title = "LSP" })
	else
		vim.notify("Auto Hover disabled", vim.log.levels.INFO, { title = "LSP" })
	end
end

vim.keymap.set(
	"n",
	"<leader><leader>Th",
	toggle_auto_hover,
	{ desc = "Toggle LSP auto hover", noremap = false, silent = true }
)
