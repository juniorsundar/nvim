-- Winbar of path and LSP symbols at the cursor. Symbols are fetched once per buffer change and
-- the cursor is matched locally, so moving the cursor sends no request.
local M = {}

local kinds = require "micro.kinds"
local devicons_ok, devicons = pcall(require, "nvim-web-devicons")

---@class micro.breadcrumbs.Symbol
---@field name string
---@field kind string SymbolKind name.
---@field range lsp.Range
---@field children micro.breadcrumbs.Symbol[]

---@class micro.breadcrumbs.Cache
---@field tick integer changedtick the symbols belong to.
---@field symbols micro.breadcrumbs.Symbol[]
---@field encoding string Position encoding of the client that sent them.

---@type table<integer, micro.breadcrumbs.Cache>
local cache = {}
---@type table<integer, true> Buffers with a `micro.lsp` key to forget.
local requested = {}
local shown = false
local SEP = "%#MicroBreadcrumbSep# > %*"
local group = vim.api.nvim_create_augroup("Breadcrumbs", { clear = true })
vim.api.nvim_del_augroup_by_id(group)

local function escape(s)
    return (s:gsub("%%", "%%%%"))
end

local function file_buf(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function eligible(win)
    return vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_win_get_config(win).relative == ""
        and file_buf(vim.api.nvim_win_get_buf(win))
end

--- Normalise DocumentSymbol[] (nested) or SymbolInformation[] (flat, `location.range`).
---@return micro.breadcrumbs.Symbol[]
local function normalise(list)
    local out = {}
    for _, s in ipairs(list or {}) do
        local range = s.range or (s.location and s.location.range)
        if range then
            out[#out + 1] = {
                name = s.name,
                kind = vim.lsp.protocol.SymbolKind[s.kind] or "",
                range = range,
                children = normalise(s.children),
            }
        end
    end
    return out
end

--- LSP range ends are exclusive.
local function contains(range, line, char)
    local s, e = range.start, range["end"]
    return (line > s.line or (line == s.line and char >= s.character))
        and (line < e.line or (line == e.line and char < e.character))
end

--- Innermost-last chain of symbols around (line, char). Flat replies are not nested, so every
--- containing symbol is kept, sorted outermost first.
local function chain(symbols, line, char, out)
    out = out or {}
    local hits = {}
    for _, s in ipairs(symbols) do
        if contains(s.range, line, char) then
            hits[#hits + 1] = s
        end
    end
    -- Outermost first: earlier start, then later end.
    table.sort(hits, function(a, b)
        local sa, sb, ea, eb = a.range.start, b.range.start, a.range["end"], b.range["end"]
        if sa.line ~= sb.line or sa.character ~= sb.character then
            return sa.line < sb.line or (sa.line == sb.line and sa.character < sb.character)
        end
        return ea.line > eb.line or (ea.line == eb.line and ea.character > eb.character)
    end)
    for _, s in ipairs(hits) do
        out[#out + 1] = s
        chain(s.children, line, char, out)
    end
    return out
end

local function path_parts(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local rel = vim.fs.relpath(vim.fn.getcwd(), name) or vim.fn.fnamemodify(name, ":~")
    local parts = vim.split(rel, "/", { trimempty = true })
    local out = {}
    for i, part in ipairs(parts) do
        if i < #parts then
            out[#out + 1] = escape(part)
        else
            local icon, hl = kinds.KINDS.File[1], "MicroKindFile"
            if devicons_ok then
                local di, dhl = devicons.get_icon(part)
                icon, hl = di or icon, dhl or hl
            end
            out[#out + 1] = ("%%#%s#%s%%* %s"):format(hl, icon, escape(part))
        end
    end
    return out
end

---@param win integer
local function render(win)
    if not shown or not vim.api.nvim_win_is_valid(win) then
        return
    end
    if not eligible(win) then
        -- New windows copy the parent's window-local winbar (but not its w: vars), crumbs included.
        if vim.api.nvim_get_option_value("winbar", { win = win, scope = "local" }):find(SEP, 1, true) then
            vim.wo[win].winbar = ""
        end
        return
    end
    local buf = vim.api.nvim_win_get_buf(win)
    local parts = path_parts(buf)
    -- Older symbols are still drawn while a refresh is pending, so typing does not blank the chain.
    local c = cache[buf]
    if c then
        local pos = vim.api.nvim_win_get_cursor(win)
        local line = vim.api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false)[1] or ""
        local char = vim.str_utfindex(line, c.encoding, math.min(pos[2], #line), false)
        for _, s in ipairs(chain(c.symbols, pos[1] - 1, char)) do
            local k = kinds.KINDS[s.kind]
            local icon = k and ("%%#MicroKind%s#%s%%* "):format(s.kind, k[1]) or ""
            parts[#parts + 1] = icon .. escape(s.name)
        end
    end
    vim.wo[win].winbar = " " .. table.concat(parts, SEP)
    vim.w[win].micro_breadcrumbs = true
end

local function render_buf(buf)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        render(win)
    end
end

--- Fetch symbols for `buf` once per changedtick. The first client with symbols wins.
---@param win? integer A window showing `buf`; any one is used when omitted.
local function refresh(buf, debounce, win)
    if not shown or not file_buf(buf) then
        return
    end
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    if cache[buf] and cache[buf].tick == tick then
        return
    end
    -- Never on behalf of a float: floats opened per window (e.g. a floating statusline) would
    -- supersede the real window's request and get a reply they cannot draw.
    if not (win and eligible(win)) then
        win = vim.iter(vim.fn.win_findbuf(buf)):find(eligible)
    end
    if not win then
        return
    end
    requested[buf] = true
    require("micro.lsp").request("breadcrumbs:" .. buf, win, "textDocument/documentSymbol", function(_, b)
        return { textDocument = vim.lsp.util.make_text_document_params(b) }
    end, function(err, result, ctx)
        if vim.api.nvim_buf_get_changedtick(buf) ~= tick then
            return false
        end
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        local symbols = not err and type(result) == "table" and normalise(result) or {}
        -- An empty answer is still cached for this tick so it is not re-asked; a later client may replace it.
        if #symbols > 0 or not (cache[buf] and cache[buf].tick == tick) then
            cache[buf] = { tick = tick, symbols = symbols, encoding = client and client.offset_encoding or "utf-16" }
            render_buf(buf)
        end
        return #symbols > 0
    end, { debounce = debounce })
end

local function clear_all()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.w[win].micro_breadcrumbs then
            vim.wo[win].winbar = ""
            vim.w[win].micro_breadcrumbs = nil
        end
    end
end

local function set_shown(on)
    shown = on
    if not on then
        pcall(vim.api.nvim_del_augroup_by_name, "Breadcrumbs")
        for buf in pairs(requested) do
            require("micro.lsp").forget("breadcrumbs:" .. buf)
        end
        cache, requested = {}, {}
        clear_all()
        return
    end
    group = vim.api.nvim_create_augroup("Breadcrumbs", { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufWinEnter", "WinEnter", "WinNew", "DirChanged" }, {
        group = group,
        callback = function(ev)
            local win = vim.api.nvim_get_current_win()
            render(win)
            refresh(ev.buf, 0, win)
        end,
    })
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "LspAttach" }, {
        group = group,
        callback = function(ev)
            refresh(ev.buf, 300)
        end,
    })
    vim.api.nvim_create_autocmd("LspDetach", {
        group = group,
        callback = function(ev)
            cache[ev.buf] = nil
            vim.schedule(function()
                render_buf(ev.buf)
            end)
        end,
    })
    vim.api.nvim_create_autocmd("BufUnload", {
        group = group,
        callback = function(ev)
            cache[ev.buf], requested[ev.buf] = nil, nil
            require("micro.lsp").forget("breadcrumbs:" .. ev.buf)
        end,
    })
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        render(win)
        refresh(vim.api.nvim_win_get_buf(win), 0, win)
    end
end

function M.enable()
    set_shown(true)
end

function M.disable()
    set_shown(false)
end

function M.toggle()
    set_shown(not shown)
end

M.subcommands = {
    breadcrumbs = {
        enable = M.enable,
        disable = M.disable,
        toggle = M.toggle,
    },
}

---@class micro.breadcrumbs.Opts
---@field show boolean Show at startup.

---@type micro.breadcrumbs.Opts
local defaults = { show = false }

---@param opts? micro.breadcrumbs.Opts
function M.setup(opts)
    local config = vim.tbl_deep_extend("force", defaults, opts or {})
    kinds.highlights()
    vim.api.nvim_set_hl(0, "MicroBreadcrumbSep", { link = "NonText", default = true })
    if config.show ~= shown then
        set_shown(config.show)
    end
end

return M
