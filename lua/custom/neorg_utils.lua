-- ~/.config/nvim/lua/custom/neorg_utils.lua

local M = {}

local neorg_loaded, neorg = pcall(require, "neorg.core")
assert(neorg_loaded, "Neorg is not loaded - please make sure to load Neorg first")
local fzf_lua_loaded, fzf_lua = pcall(require, "fzf-lua")
assert(fzf_lua_loaded, "fzf-lua is not loaded - please make sure to load fzf-lua first")
local builtin = require("fzf-lua.previewer.builtin")

local function extract_metadata(norg_address)
	-- Read the entire file content
	local file = io.open(norg_address, "r")
	if not file then
		print("Could not open file: " .. norg_address)
		return nil
	end
	local content = file:read("*all")
	file:close()

	-- Extract metadata block
	local metadata_block = content:match("@document%.meta(.-)@end")
	if not metadata_block then
		print("No metadata found in file: " .. norg_address)
		return nil
	end

	-- Parse metadata block into a table
	local metadata = {}
	for line in metadata_block:gmatch("[^\r\n]+") do
		local key, value = line:match("^%s*(%w+):%s*(.-)%s*$")
		if key and value then
			if value:match("^%[.-%]$") then
				-- Handle array values (categories)
				local array_values = {}
				for item in value:gmatch("%[(.-)%]") do
					table.insert(array_values, item)
				end
				metadata[key] = array_values
			else
				metadata[key] = value
			end
		end
	end

	return metadata
end

function M.neorg_agenda()
	-- rg '\* \(\s*(-?)\s*\)' --glob '*.norg'
	local current_workspace = neorg.modules.get_module("core.dirman").get_current_workspace()
	local base_directory = current_workspace[2]

	local rg_command = [[rg '\* \(\s*(-?)\s*\)' --glob '*.norg' --line-number ]] .. base_directory
	local rg_results = vim.fn.system(rg_command)

	local lines = {}
	for line in rg_results:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	local quickfix_list = {}

	for _, line in ipairs(lines) do
		local file, lnum, text = line:match("([^:]+):(%d+):(.*)")
		if file and lnum and text then
			table.insert(quickfix_list, {
				filename = file,
				lnum = tonumber(lnum),
				text = text,
			})
		end
	end
	-- Create a new buffer for the quickfix list
	local buf = vim.api.nvim_create_buf(false, true)

	-- Set the buffer name
	-- vim.api.nvim_buf_set_name(buf, "Quickfix.norg")

	-- Prepare the lines to be written to the buffer
	local buffer_lines = {}
	local current_file = nil

	for _, entry in ipairs(quickfix_list) do
		if current_file ~= entry.filename then
			if current_file then
				table.insert(buffer_lines, "") -- Add a blank line between different files
			end
            local file_metadata = extract_metadata(entry.filename)
            if file_metadata then
                table.insert(buffer_lines, "{:" .. entry.filename .. ":}[" .. file_metadata.title .. "]") -- Add the filename as a header
            else
                table.insert(buffer_lines, "{:" .. entry.filename .. ":}") -- Add the filename as a header
            end
			current_file = entry.filename
		end
		table.insert(buffer_lines, entry.text)
	end

	-- Set the buffer lines
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffer_lines)

	-- Open the buffer in a new split window
	vim.cmd("split")
	vim.api.nvim_win_set_buf(0, buf)

	vim.api.nvim_set_option_value("filetype", "norg", { buf = buf })
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_option_value("readonly", true, { buf = buf })
	vim.api.nvim_set_option_value("wrap", false, { win = 0 })
	vim.api.nvim_set_option_value("conceallevel", 2, { win = 0 })

	-- Optional: Set filetype to norg for syntax highlighting (if available)
	-- vim.api.nvim_buf_set_option(buf, "filetype", "norg")

	-- -- Function to set quickfix list in Neovim
	-- local function set_quickfix_list(qflist)
	-- 	vim.fn.setqflist(qflist, "r")
	-- 	vim.cmd("copen")
	-- end
	--
	-- -- Call the function to set the quickfix list
	-- set_quickfix_list(quickfix_list)
end

function M.neorg_node_injector()
	local current_workspace = neorg.modules.get_module("core.dirman").get_current_workspace()
	local base_directory = current_workspace[2]

	local norg_files_output = vim.fn.systemlist("fdfind -e norg --type f --base-directory " .. base_directory)
	local norg_files = table.concat(norg_files_output, " ")
	local rg_command = 'rg --multiline "(?s)@document\\.meta.*?title:\\s+(.*?)\\s+@end" '
		.. norg_files
		.. " "
		.. base_directory
	local rg_results = vim.fn.system(rg_command)

	local titles = {}
	for line in rg_results:gmatch("[^\r\n]+") do
		if line:find("title:") then
			table.insert(titles, line)
		end
	end

	local filtered_results = table.concat(titles, "\n")

	local title_path_pairs = {}
	for line in filtered_results:gmatch("[^\r\n]+") do
		local file_path, title = line:match("^(.-):(.*)$")
		_, title = title:match("^(.-): (.*)$")
		title_path_pairs[title] = file_path
	end

	local workspace_previewer = builtin.buffer_or_file:extend()
	function workspace_previewer:new(o, opts, fzf_win)
		workspace_previewer.super.new(self, o, opts, fzf_win)
		setmetatable(self, workspace_previewer)
		return self
	end

	function workspace_previewer:parse_entry(entry_str)
		return {
			path = title_path_pairs[entry_str],
			line = 1,
			col = 1,
		}
	end

	local navigate_to = function(selected)
		vim.notify("Navigating to --> " .. selected[1])
		vim.cmd("e " .. title_path_pairs[selected[1]])
	end

	local paste_address = function(selected)
		vim.notify("pasting address of --> " .. selected[1])
		local escaped_prefix = base_directory:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
		local relative_path = title_path_pairs[selected[1]]:gsub("^" .. escaped_prefix, "")
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local hyperlink = "{:$"
			.. relative_path:sub(relative_path:sub(1, 1) == "." and 2 or 1, -6)
			.. ":}["
			.. selected[1]
			.. "]"
		vim.api.nvim_put({ hyperlink }, "", true, true)
		vim.api.nvim_win_set_cursor(0, cursor_pos)
	end

	local function table_keys(tbl)
		local keys = {}
		for key, _ in pairs(tbl) do
			table.insert(keys, key)
		end
		return keys
	end

	local prompt = "Navigate to -> "
	fzf_lua.fzf_exec(table_keys(title_path_pairs), {
		previewer = workspace_previewer,
		prompt = prompt,
		actions = {
			["default"] = navigate_to,
			["ctrl-i"] = paste_address,
		},
	})
end

function M.neorg_workspace_selector()
	local workspaces = neorg.modules.get_module("core.dirman").get_workspaces()
	local workspace_names = {}

	for name in pairs(workspaces) do
		table.insert(workspace_names, name)
	end

	local workspace_previewer = builtin.buffer_or_file:extend()
	function workspace_previewer:new(o, opts, fzf_win)
		workspace_previewer.super.new(self, o, opts, fzf_win)
		setmetatable(self, workspace_previewer)
		self.win.conceallevel = 2
		return self
	end

	function workspace_previewer:parse_entry(entry_str)
		local path = workspaces[entry_str]
		return {
			path = path .. "/index.norg",
			line = 1,
			col = 1,
		}
	end

	local workspace_set = function(selected)
		vim.cmd("Neorg workspace " .. selected[1])
	end

	local workspace_open = function(selected)
		vim.cmd("Neorg workspace " .. selected[1])
		vim.cmd("Neorg index")
	end

	local prompt = "Select Neorg Directory -> "
	fzf_lua.fzf_exec(workspace_names, {
		previewer = workspace_previewer,
		prompt = prompt,
		actions = {
			["default"] = workspace_set,
			["ctrl-i"] = workspace_open,
		},
	})
end

function M.show_backlinks()
	local function deep_copy(orig)
		local orig_type = type(orig)
		local copy
		if orig_type == "table" then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
				copy[deep_copy(orig_key)] = deep_copy(orig_value)
			end
			setmetatable(copy, deep_copy(getmetatable(orig)))
		else
			copy = orig
		end
		return copy
	end

	local current_workspace = neorg.modules.get_module("core.dirman").get_current_workspace()
	local base_directory = current_workspace[2]

	local current_file_path = vim.fn.expand("%:p")
	local escaped_base_path = base_directory:gsub("([^%w])", "%%%1")
	local relative_path = current_file_path:match("^" .. escaped_base_path .. "/(.+)%..+")

	local cache_file_path = base_directory .. "/cache.json"
	local file = io.open(cache_file_path, "r")
	if not file then
		vim.notify("Could not open cache.json file: " .. cache_file_path, vim.log.levels.ERROR)
		return
	end
	local content = file:read("*a")
	file:close()

	local cache = vim.fn.json_decode(content)
	if not cache[relative_path] or not cache[relative_path]["backlinks"] then
		vim.notify("No backlinks found for: " .. relative_path, vim.log.levels.ERROR)
		return
	end

	local backlinks = deep_copy(cache[relative_path]["backlinks"])
	local backlink_names = {}
	local backlink_stats = {}
	for _, link in ipairs(backlinks) do
		table.insert(backlink_names, cache[link.match]["metadata"].title)
		backlink_stats[cache[link.match]["metadata"].title] = { file = link.match, line = link.line, col = link.col }
	end

	local backlinks_previewer = builtin.buffer_or_file:extend()
	function backlinks_previewer:new(o, opts, fzf_win)
		backlinks_previewer.super.new(self, o, opts, fzf_win)
		setmetatable(self, backlinks_previewer)
		return self
	end

	function backlinks_previewer:parse_entry(backlink_addr)
		local backlink_stat = backlink_stats[backlink_addr]
		return {
			path = base_directory .. "/" .. backlink_stat.file .. ".norg",
			line = backlink_stat.line,
			col = backlink_stat.col,
		}
	end

	function backlinks_previewer:gen_winopts()
		local new_winopts = {
			conceallevel = 2,
		}
		return vim.tbl_extend("force", self.winopts, new_winopts)
	end

	local open_backlink = function(selected)
		local backlink_path = base_directory .. "/" .. backlink_stats[selected[1]].file .. ".norg"
		vim.cmd(string.format("e +%d %s", backlink_stats[selected[1]].line, backlink_path))
	end

	local prompt = "Select Backlink -> "
	fzf_lua.fzf_exec(backlink_names, {
		previewer = backlinks_previewer,
		prompt = prompt,
		actions = {
			["default"] = open_backlink,
		},
	})
end

return M
