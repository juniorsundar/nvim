local M = {}

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
            local icon = kind_icons[symbol.kind] or ""
            table.insert(path, icon .. " " .. symbol.name)
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
---@param winnr number Window the request was made for.
---@return boolean? -- True once the winbar has been set from this reply.
local function lsp_callback(err, symbols, ctx, winnr)
    if err or not symbols then
        vim.o.winbar = "" -- Clear winbar on error or no symbols
        return
    end

    ---@type number[]
    local pos = vim.api.nvim_win_get_cursor(winnr)
    ---@type number
    local cursor_line = pos[1] - 1
    -- Symbol ranges are in the client's position encoding; the cursor column is a byte index.
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    local line_text = vim.api.nvim_buf_get_lines(ctx.bufnr, cursor_line, cursor_line + 1, false)[1] or ""
    ---@type number
    local cursor_char =
        vim.str_utfindex(line_text, client and client.offset_encoding or "utf-16", math.min(pos[2], #line_text), false)

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
            table.insert(
                breadcrumbs,
                "%#" .. (icon_hl or "Normal") .. "#" .. (icon or file_icon) .. "%#Normal#" .. " " .. component
            )
        else
            table.insert(breadcrumbs, folder_icon .. " " .. component)
        end
    end

    find_symbol_path(symbols, cursor_line, cursor_char, breadcrumbs)

    ---@type string
    local breadcrumb_string = table.concat(breadcrumbs, " > ")

    if breadcrumb_string ~= "" then
        vim.api.nvim_set_option_value("winbar", breadcrumb_string, { win = winnr })
    else
        vim.api.nvim_set_option_value("winbar", " ", { win = winnr })
    end
    return true
end

--- Requests document symbols from the LSP to update the breadcrumbs.
--- This function initiates the request; `lsp_callback` handles the result.
---@return nil
local shown = false

local function breadcrumbs_set(debounce)
    if not shown then
        return
    end

    ---@type number
    local winnr = vim.api.nvim_get_current_win()
    ---@type number
    local bufnr = vim.api.nvim_win_get_buf(winnr)

    -- Don't run on non-file buffers (e.g., help tags)
    if vim.uri_from_bufnr(bufnr):match "^(%a+):" ~= "file" then
        vim.o.winbar = ""
        return
    end

    require("micro.lsp").request("breadcrumbs", winnr, "textDocument/documentSymbol", function(_, buf)
        return { textDocument = vim.lsp.util.make_text_document_params(buf) }
    end, function(err, symbols, ctx)
        return lsp_callback(err, symbols, ctx, winnr)
    end, { debounce = debounce })
end

local function debounced_breadcrumbs_set()
    breadcrumbs_set(200)
end

local function set_shown(on)
    shown = on
    if not on then
        pcall(vim.api.nvim_del_augroup_by_name, "Breadcrumbs")
        require("micro.lsp").cancel "breadcrumbs"
        vim.o.winbar = ""
        return
    end
    local group = vim.api.nvim_create_augroup("Breadcrumbs", { clear = true })
    vim.api.nvim_create_autocmd("CursorHold", {
        group = group,
        callback = debounced_breadcrumbs_set,
        desc = "Set breadcrumbs.",
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = group,
        callback = function()
            vim.o.winbar = ""
        end,
        desc = "Clear breadcrumbs when leaving window.",
    })
    debounced_breadcrumbs_set()
end

--- Show breadcrumbs in the winbar. Works whether or not the module was set up.
function M.enable()
    vim.notify("Breadcrumbs enabled", vim.log.levels.INFO, { title = "LSP" })
    set_shown(true)
end

function M.disable()
    vim.notify("Breadcrumbs disabled", vim.log.levels.INFO, { title = "LSP" })
    set_shown(false)
end

function M.toggle()
    if shown then
        M.disable()
    else
        M.enable()
    end
end

-- Export subcommands for the global :Micro command
M.subcommands = {
    breadcrumbs = {
        enable = M.enable,
        disable = M.disable,
        toggle = M.toggle,
    },
}

local defaults = {
    show = false, -- show breadcrumbs at startup
}

function M.setup(opts)
    local config = vim.tbl_deep_extend("force", defaults, opts or {})
    set_shown(config.show)
end

return M
