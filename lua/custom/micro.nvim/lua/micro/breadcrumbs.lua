local M = {}

local devicons_ok, devicons = pcall(require, "nvim-web-devicons")

local folder_icon = "%#Conditional#" .. "󰉋" .. "%#Normal#"
local file_icon = "󰈙"

-- Icons keyed by LSP SymbolKind.
local kind_icons = {
    [1] = "%#File#" .. "󰈙" .. "%#Normal#",
    [2] = "%#Module#" .. "󰠱" .. "%#Normal#",
    [3] = "%#Structure#" .. "" .. "%#Normal#",
    [19] = "%#Keyword#" .. "󰌋" .. "%#Normal#",
    [5] = "%#Class#" .. "" .. "%#Normal#",
    [6] = "%#Method#" .. "󰆧" .. "%#Normal#",
    [7] = "%#Property#" .. "" .. "%#Normal#",
    [8] = "%#Field#" .. "" .. "%#Normal#",
    [9] = "%#Function#" .. "" .. "%#Normal#",
    [10] = "%#Enum#" .. "" .. "%#Normal#",
    [11] = "%#Type#" .. "" .. "%#Normal#",
    [12] = "%#Function#" .. "󰊕" .. "%#Normal#",
    [13] = "%#None#" .. "󰂡" .. "%#Normal#",
    [14] = "%#Constant#" .. "󰏿" .. "%#Normal#",
    [15] = "%#String#" .. "" .. "%#Normal#",
    [16] = "%#Number#" .. "" .. "%#Normal#",
    [17] = "%#Boolean#" .. "" .. "%#Normal#",
    [18] = "%#Array#" .. "" .. "%#Normal#",
    [20] = "%#Class#" .. "" .. "%#Normal#",
    [4] = "",
    [21] = "󰟢",
    [22] = "",
    [23] = "%#Struct#" .. "" .. "%#Normal#",
    [24] = "",
    [25] = "",
    [26] = "󰅲",
}

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

local function find_symbol_path(symbol_list, line, char, path)
    if not symbol_list or #symbol_list == 0 then
        return false
    end

    for _, symbol in ipairs(symbol_list) do
        if range_contains_pos(symbol.range, line, char) then
            local icon = kind_icons[symbol.kind] or ""
            table.insert(path, icon .. " " .. symbol.name)
            find_symbol_path(symbol.children, line, char, path)
            return true
        end
    end
    return false
end

local function lsp_callback(err, symbols, ctx, winnr)
    if err or not symbols then
        vim.o.winbar = "" -- Clear winbar on error or no symbols
        return
    end

    ---@type number[]
    local pos = vim.api.nvim_win_get_cursor(winnr)
    local cursor_line = pos[1] - 1
    -- Symbol ranges are in the client's position encoding; the cursor column is a byte index.
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    local line_text = vim.api.nvim_buf_get_lines(ctx.bufnr, cursor_line, cursor_line + 1, false)[1] or ""
    local cursor_char =
        vim.str_utfindex(line_text, client and client.offset_encoding or "utf-16", math.min(pos[2], #line_text), false)

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
        ---@type string?
        local root_dir = clients[1].root_dir
        if root_dir == nil then
            relative_path = file_path
        else
            relative_path = vim.fs.relpath(root_dir, file_path)
        end
    else
        local root_dir = vim.fn.getcwd(0)
        relative_path = vim.fs.relpath(root_dir, file_path)
    end

    local breadcrumbs = {}

    if not relative_path then
        return
    end

    local path_components = vim.split(relative_path, "[/\\]", { trimempty = true })
    local num_components = #path_components

    for i, component in ipairs(path_components) do
        if i == num_components then
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

local shown = false

local function breadcrumbs_set(debounce)
    if not shown then
        return
    end

    local winnr = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_win_get_buf(winnr)

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
