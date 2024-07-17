-- ~/.config/nvim/lua/custom/neorg_utils.lua

local M = {}

local neorg_loaded, neorg = pcall(require, "neorg.core")
assert(neorg_loaded, "Neorg is not loaded - please make sure to load Neorg first")

local fzf_lua_loaded, fzf_lua = pcall(require, "fzf-lua")
assert(fzf_lua_loaded, "fzf-lua is not loaded - please make sure to load fzf-lua first")
local builtin = require("fzf-lua.previewer.builtin")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values -- allows us to use the values from the users config
local make_entry = require("telescope.make_entry")
local actions = require("telescope.actions")
local actions_set = require("telescope.actions.set")
local state = require("telescope.actions.state")

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
                table.insert(buffer_lines, "===")
                table.insert(buffer_lines, "")
                table.insert(buffer_lines, "{:" .. entry.filename .. ":}[" .. file_metadata.title .. "]") -- Add the filename as a header
            else
                table.insert(buffer_lines, "===")
                table.insert(buffer_lines, "")
                table.insert(buffer_lines, "{:" .. entry.filename .. ":}") -- Add the filename as a header
            end
            current_file = entry.filename
        end
        table.insert(buffer_lines, entry.text)
    end

    -- Set the buffer lines
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffer_lines)

    -- Open the buffer in a new split window
    vim.cmd("e")
    vim.api.nvim_win_set_buf(0, buf)

    vim.api.nvim_set_option_value("filetype", "norg", { buf = buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_set_option_value("readonly", true, { buf = buf })
    vim.api.nvim_set_option_value("wrap", false, { win = 0 })
    vim.api.nvim_set_option_value("conceallevel", 2, { win = 0 })
    vim.api.nvim_set_option_value("foldlevel", 999, { win = 0 })

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

    local norg_files_output = vim.fn.systemlist("fd -e norg --type f --base-directory " .. base_directory)
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
        table.insert(title_path_pairs, { title, file_path })
    end

    local opts = {}
    opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)
    pickers
        .new(opts, {
            prompt_title = "Find Norg Files",
            finder = finders.new_table({
                results = title_path_pairs,
                entry_maker = function(entry)
                    return {
                        value = entry[2],
                        display = entry[1],
                        ordinal = entry[1]
                    }
                end
            }),
            previewer = conf.file_previewer(opts),
            sorter = conf.file_sorter(opts),
            layout_strategy = "vertical",
            attach_mappings = function(prompt_bufnr, map)
                map('i', '<C-i>', function()
                    local entry = state.get_selected_entry()
                    local current_file_path = entry.value
                    local escaped_base_path = base_directory:gsub("([^%w])", "%%%1")
                    local relative_path = current_file_path:match("^" .. escaped_base_path .. "/(.+)%..+")
                    -- Insert at location
                    actions.close(prompt_bufnr)
                    vim.api.nvim_put({ "{:$/" .. relative_path .. ":}[" .. entry.display .. "]" }, "", false, true)
                end)
                return true
            end
        })
        :find()
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
    local current_workspace = neorg.modules.get_module("core.dirman").get_current_workspace()
    local base_directory = current_workspace[2]

    local current_file_path = vim.fn.expand("%:p")
    local escaped_base_path = base_directory:gsub("([^%w])", "%%%1")
    local relative_path = current_file_path:match("^" .. escaped_base_path .. "/(.+)%..+")
    local search_path = "{:$/" .. relative_path .. ":"

    local rg_command = 'rg --fixed-strings '
    .. "'"
    .. search_path
    .. "'"
    .. " "
    .. "-g '*.norg' --with-filename --line-number "
    .. base_directory
    local rg_results = vim.fn.system(rg_command)

    -- Split the results by lines
    local matches = {}
    local self_title = extract_metadata(current_file_path)["title"]
    for line in rg_results:gmatch("([^\n]+)") do
        -- table.insert(lines, line)
        local file, lineno = line:match("^(.-):(%d+):")
        local metadata = extract_metadata(file)
        if metadata["title"] ~= self_title then
            table.insert(matches, {file, lineno, metadata["title"]} )
        end
    end

    local opts = {}
    opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)
    pickers
        .new(opts, {
            prompt_title = "Backlinks",
            finder = finders.new_table({
                results = matches,
                entry_maker = function(entry)
                local filename = entry[1]
                local line_number = tonumber(entry[2])
                local title = entry[3]

                return {
                    value = filename,
                    display = title .. "  @" .. line_number,
                    ordinal = title,
                    filename = filename,
                    lnum = line_number
                }
            end
            }),
            previewer = conf.grep_previewer(opts),
            sorter = conf.file_sorter(opts),
            layout_strategy = "vertical",
        })
        :find()

end

return M
