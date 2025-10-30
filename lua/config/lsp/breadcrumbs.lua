vim.lsp.breadcrumbs = {
    enabled = true,
}
-- Safely try to load nvim-web-devicons
---@type boolean
local devicons_ok, devicons = pcall(require, "nvim-web-devicons")

-- Default icons
---@type string
local folder_icon = "%#Conditional#" .. "󰉋" .. "%#Normal#"
---@type string
local file_icon = "󰈙"

-- Map of LSP SymbolKind (which is a number) to a string icon
---@type table<number, string>
local kind_icons = {
    [1] = "%#File#" .. "󰈙" .. "%#Normal#", -- file
    [2] = "%#Module#" .. "󰠱" .. "%#Normal#", -- module
    [3] = "%#Structure#" .. "" .. "%#Normal#", -- namespace
    [19] = "%#Keyword#" .. "󰌋" .. "%#Normal#", -- key
    [5] = "%#Class#" .. "" .. "%#Normal#", -- class
    [6] = "%#Method#" .. "󰆧" .. "%#Normal#", -- method
    [7] = "%#Property#" .. "" .. "%#Normal#", -- property
    [8] = "%#Field#" .. "" .. "%#Normal#", -- field
    [9] = "%#Function#" .. "" .. "%#Normal#", -- constructor
    [10] = "%#Enum#" .. "" .. "%#Normal#", -- enum
    [11] = "%#Type#" .. "" .. "%#Normal#", -- interface
    [12] = "%#Function#" .. "󰊕" .. "%#Normal#", -- function
    [13] = "%#None#" .. "󰂡" .. "%#Normal#", -- variable
    [14] = "%#Constant#" .. "󰏿" .. "%#Normal#", -- constant
    [15] = "%#String#" .. "" .. "%#Normal#", -- string
    [16] = "%#Number#" .. "" .. "%#Normal#", -- number
    [17] = "%#Boolean#" .. "" .. "%#Normal#", -- boolean
    [18] = "%#Array#" .. "" .. "%#Normal#", -- array
    [20] = "%#Class#" .. "" .. "%#Normal#", -- object
    [4] = "", -- package
    [21] = "󰟢", -- null
    [22] = "", -- enum-member
    [23] = "%#Struct#" .. "" .. "%#Normal#", -- struct
    [24] = "", -- event
    [25] = "", -- operator
    [26] = "󰅲", -- type-parameter
}

--- Checks if a cursor position (line, char) is inside an LSP range.
---@param range any LSP Range object
---@param line number Zero-indexed line number
---@param char number Zero-indexed character number
---@return boolean
local function range_contains_pos(range, line, char)
    local start = range.start
    local stop = range["end"]

    if line < start.line or line > stop.line then
        return false
    end

    if line == start.line and char < start.character then
        return false
    end

    if line == stop.line and char > stop.character then
        return false
    end

    return true
end

--- Recursively finds the symbol path at the current cursor position.
---@param symbol_list any[]? List of LSP DocumentSymbol items
---@param line number Zero-indexed line number
---@param char number Zero-indexed character number
---@param path string[] An array to store the resulting path components (mutated).
---@return boolean -- True if a symbol was found and added to the path.
local function find_symbol_path(symbol_list, line, char, path)
    if not symbol_list or #symbol_list == 0 then
        return false
    end

    for _, symbol in ipairs(symbol_list) do
        if range_contains_pos(symbol.range, line, char) then
            -- Found the symbol, add it to the path
            ---@type string
            local icon = kind_icons[symbol.kind] or "" -- Default icon
            table.insert(path, icon .. " " .. symbol.name)
            -- Recurse into its children to find the most specific symbol
            find_symbol_path(symbol.children, line, char, path)
            return true
        end
    end
    return false
end

--- Callback for the textDocument/documentSymbol LSP request.
--- Builds the full breadcrumb string (file path + symbol path) and sets the winbar.
---@param err any? Error object if the request failed.
---@param symbols any[]? The list of DocumentSymbol items from the LSP.
---@param ctx table Context object (includes bufnr).
---@param config table Client config.
local function lsp_callback(err, symbols, ctx, config)
    if err or not symbols then
        vim.o.winbar = "" -- Clear winbar on error or no symbols
        return
    end

    ---@type number
    local winnr = vim.api.nvim_get_current_win()
    ---@type number[]
    local pos = vim.api.nvim_win_get_cursor(0) -- {line, col}
    ---@type number
    local cursor_line = pos[1] - 1 -- LSP is 0-indexed
    ---@type number
    local cursor_char = pos[2]

    ---@type string
    local file_path = vim.fn.bufname(ctx.bufnr)
    if not file_path or file_path == "" then
        vim.o.winbar = "[No Name]"
        return
    end

    ---@type string?
    local relative_path

    ---@type vim.lsp.Client[]
    local clients = vim.lsp.get_clients { bufnr = ctx.bufnr }

    if #clients > 0 and clients[1].root_dir then
        -- Try to get relative path from LSP root
        ---@type string?
        local root_dir = clients[1].root_dir
        if root_dir == nil then
            relative_path = file_path
        else
            relative_path = vim.fs.relpath(root_dir, file_path)
        end
    else
        -- Fallback to CWD
        ---@type string
        local root_dir = vim.fn.getcwd(0)
        relative_path = vim.fs.relpath(root_dir, file_path)
    end

    ---@type string[]
    local breadcrumbs = {}

    if not relative_path then
        return -- Failed to get a relative path
    end

    -- Split the path into components
    ---@type string[]
    local path_components = vim.split(relative_path, "[/\\]", { trimempty = true })
    ---@type number
    local num_components = #path_components

    -- Build the file path part of the breadcrumbs
    for i, component in ipairs(path_components) do
        if i == num_components then
            -- Last component is the file name, use devicon
            ---@type string?
            local icon
            ---@type string?
            local icon_hl

            if devicons_ok then
                icon, icon_hl = devicons.get_icon(component)
            end
            table.insert(breadcrumbs, "%#" .. icon_hl .. "#" .. (icon or file_icon) .. "%#Normal#" .. " " .. component)
        else
            -- Path component is a folder
            table.insert(breadcrumbs, folder_icon .. " " .. component)
        end
    end

    -- Find and append the symbol path
    find_symbol_path(symbols, cursor_line, cursor_char, breadcrumbs)

    ---@type string
    local breadcrumb_string = table.concat(breadcrumbs, " > ")

    -- Set the winbar
    if breadcrumb_string ~= "" then
        vim.api.nvim_set_option_value("winbar", breadcrumb_string, { win = winnr })
    else
        vim.api.nvim_set_option_value("winbar", " ", { win = winnr })
    end
end

--- Requests document symbols from the LSP to update the breadcrumbs.
--- This function initiates the request; `lsp_callback` handles the result.
---@return nil
local function breadcrumbs_set()
    if not vim.lsp.breadcrumbs.enabled then
        return
    end

    ---@type number
    local bufnr = vim.api.nvim_get_current_buf()
    ---@type number
    ---@diagnostic disable-next-line: unused-local
    local winnr = vim.api.nvim_get_current_buf() -- Note: This is buffer handle, not window. Not used.

    ---@type vim.lsp.Client[]
    local clients = vim.lsp.get_clients { bufnr = bufnr }

    -- Exit if no clients or client doesn't support documentSymbol
    if #clients == 0 then
        return
    elseif not clients[1].supports_method "textDocument/documentSymbol" then
        return
    end

    ---@type string
    local uri = vim.lsp.util.make_text_document_params(bufnr)["uri"]
    if not uri then
        vim.print "Error: Could not get URI for buffer. Is it saved?"
        return
    end

    local params = {
        textDocument = {
            uri = uri,
        },
    }

    -- Don't run on non-file buffers (e.g., help tags)
    ---@type string
    local buf_src = uri:sub(1, uri:find ":" - 1)
    if buf_src ~= "file" then
        vim.o.winbar = ""
        return
    end

    -- Make the async LSP request
    local result, _ = pcall(vim.lsp.buf_request, bufnr, "textDocument/documentSymbol", params, lsp_callback)

    if not result then
        -- Request failed to send
        return
    end
end

-- Create a dedicated augroup
---@type number
local breadcrumbs_augroup = vim.api.nvim_create_augroup("Breadcrumbs", { clear = true })

-- Update breadcrumbs when the cursor moves
vim.api.nvim_create_autocmd({ "CursorHold" }, {
    group = breadcrumbs_augroup,
    callback = breadcrumbs_set,
    desc = "Set breadcrumbs.",
})

-- Clear breadcrumbs when leaving the window
vim.api.nvim_create_autocmd({ "WinLeave" }, {
    group = breadcrumbs_augroup,
    callback = function()
        vim.o.winbar = ""
    end,
    desc = "Clear breadcrumbs when leaving window.",
})

local function toggle_breadcrumbs()
    if vim.lsp.breadcrumbs == nil then
        vim.notify("`vim.lsp.breadcrumbs` doesn't exists!", vim.log.levels.WARN, { title = "LSP" })
        return
    end
    if vim.lsp.breadcrumbs.enabled == nil then
        vim.notify("`vim.lsp.breadcrumbs.enabled` doesn't exists!", vim.log.levels.WARN, { title = "LSP" })
        return
    end
    vim.lsp.breadcrumbs.enabled = not vim.lsp.breadcrumbs.enabled
    if vim.lsp.breadcrumbs.enabled then
        vim.notify("Auto Hover enabled", vim.log.levels.INFO, { title = "LSP" })
    else
        vim.notify("Auto Hover disabled", vim.log.levels.INFO, { title = "LSP" })
        vim.o.winbar = ""
    end
end

vim.keymap.set(
    "n",
    "<leader><leader>TB",
    toggle_breadcrumbs,
    { desc = "Toggle LSP breadcrumbs", noremap = false, silent = true }
)
