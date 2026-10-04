-- Backend for native completion: drops stale LSP replies and routes path vs language contexts.
-- Native Neovim still owns the menu, matching, requests, snippets and acceptance.
local M = {}

---@alias micro.completion.Route "language"|"path"|"disabled"

---@class micro.completion.Sources
---@field lsp boolean
---@field buffer boolean Words from the current buffer.
---@field path boolean

---@class micro.completion.Opts
---@field min_word_length integer
---@field debounce integer Milliseconds; ignored by Neovim 0.12.5.
---@field prefer_lsp boolean Show a shared word once, as the LSP item, and list LSP items first.
---@field skip_kinds string[] LSP CompletionItemKind names dropped from server replies.
---@field sources micro.completion.Sources
---@field icons boolean|table<string, string> `true` for built-in glyphs; a table overrides entries.

---@alias micro.completion.Cmd fun(dispatchers: vim.lsp.rpc.Dispatchers, config: vim.lsp.ClientConfig): vim.lsp.rpc.Client

---@class micro.completion.Ticket
---@field snapshot table Editor state when the request was sent.
---@field retire fun()
---@field dead? boolean
---@field id? integer

---@type micro.completion.Opts
local defaults = {
    min_word_length = 2,
    debounce = 80,
    prefer_lsp = true,
    skip_kinds = {},
    sources = { lsp = true, buffer = true, path = true },
    icons = false,
}

local KINDS = require("micro.kinds").KINDS
local opts = vim.deepcopy(defaults)
local glyphs = {}

local api = vim.api
local epoch = 0
-- Weak-keyed so abandoned tickets never leak.
---@type table<micro.completion.Ticket, true>
local active = setmetatable({}, { __mode = "k" })
-- original cmd -> wrapper, and wrapper -> true, for idempotent decoration.
local wrappers = setmetatable({}, { __mode = "k" })
local is_wrapper = setmetatable({}, { __mode = "k" })
local watched = {}
local group = api.nvim_create_augroup("micro_completion", { clear = true })

local excluded_filetypes = { refer_input = true, refer_results = true }

local function excluded(buf)
    return vim.b[buf].completion == false
        or vim.bo[buf].buftype ~= ""
        or excluded_filetypes[vim.bo[buf].filetype] == true
end

-- Edits outside the request line expire tickets. `changedtick` cannot be used:
-- native completion temporarily edits and restores the query line itself.
local function watch(buf)
    if watched[buf] then
        return
    end
    watched[buf] = api.nvim_buf_attach(buf, false, {
        on_lines = function(_, b, _, first, last, new_last)
            for ticket in pairs(active) do
                local row = ticket.snapshot.cursor[1]
                if ticket.snapshot.buf == b and (first ~= row - 1 or last ~= row or new_last ~= row) then
                    ticket.retire()
                end
            end
        end,
        on_detach = function(_, b)
            watched[b] = nil
        end,
    })
end

--- Expire every in-flight completion reply, e.g. when dismissing with no menu open.
function M.invalidate()
    epoch = epoch + 1
    for ticket in pairs(active) do
        ticket.retire()
    end
end

local function snapshot()
    local cursor = api.nvim_win_get_cursor(0)
    local line = api.nvim_get_current_line()
    return {
        epoch = epoch,
        buf = api.nvim_get_current_buf(),
        win = api.nvim_get_current_win(),
        cursor = cursor,
        prefix = line:sub(1, cursor[2]),
        suffix = line:sub(cursor[2] + 1),
        complete = vim.bo.complete,
        omnifunc = vim.bo.omnifunc,
        iskeyword = vim.bo.iskeyword,
        uri = vim.uri_from_bufnr(0),
    }
end

--- True if the reply for `ticket` still matches the editor state it was requested in.
---@param ticket micro.completion.Ticket
---@return boolean
local function current(ticket)
    local s = ticket.snapshot
    if ticket.dead or epoch ~= s.epoch or excluded(s.buf) then
        return false
    end
    local mode = api.nvim_get_mode().mode
    if (mode ~= "i" and mode ~= "ic") or api.nvim_get_current_buf() ~= s.buf or api.nvim_get_current_win() ~= s.win then
        return false
    end
    local cursor = api.nvim_win_get_cursor(0)
    local line = api.nvim_get_current_line()
    local prefix, suffix = line:sub(1, cursor[2]), line:sub(cursor[2] + 1)
    local extra = prefix:sub(#s.prefix + 1)
    -- TODO: only keyword-prefix extension is accepted; other edits expire the reply
    -- instead of rebasing native replacement ranges.
    return cursor[1] == s.cursor[1]
        and prefix:sub(1, #s.prefix) == s.prefix
        and suffix == s.suffix
        and vim.fn.matchstr(extra, "^\\k*$") == extra
        and vim.bo.complete == s.complete
        and vim.bo.omnifunc == s.omnifunc
        and vim.bo.iskeyword == s.iskeyword
        and vim.uri_from_bufnr(0) == s.uri
        and vim.fn.complete_info({ "selected" }).selected < 0
end

--- Loaded buffer for `uri`; unlike `vim.uri_to_bufnr` it never creates one.
---@param uri string
---@return integer?
local function request_buf(uri)
    local cur = api.nvim_get_current_buf()
    if vim.uri_from_bufnr(cur) == uri then
        return cur
    end
    for _, buf in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_loaded(buf) and vim.uri_from_bufnr(buf) == uri then
            return buf
        end
    end
end

--- Drop items whose kind is in `opts.skip_kinds`; unknown kind names are ignored.
---@param result? lsp.CompletionList|lsp.CompletionItem[]
---@return lsp.CompletionList|lsp.CompletionItem[]|nil
local function skip_kinds(result)
    if type(result) ~= "table" or #opts.skip_kinds == 0 then
        return result
    end
    local skip = {}
    for _, name in ipairs(opts.skip_kinds) do
        skip[vim.lsp.protocol.CompletionItemKind[name] or 0] = true
    end
    local function keep(items)
        return vim.tbl_filter(function(item)
            return not skip[item.kind]
        end, items)
    end
    if result.items then
        return vim.tbl_extend("force", result, { items = keep(result.items) })
    end
    return keep(result)
end

--- Wrap an LSP `cmd` so stale completion replies are dropped. Idempotent; must run before the client starts.
---@param cmd string[]|micro.completion.Cmd
---@return micro.completion.Cmd
function M.wrap_cmd(cmd)
    if is_wrapper[cmd] then
        ---@cast cmd micro.completion.Cmd
        return cmd
    end
    if wrappers[cmd] then
        return wrappers[cmd]
    end
    local function wrapper(dispatchers, config)
        local pending, closed = {}, false
        local hooks = vim.tbl_extend("force", dispatchers, {
            on_exit = function(...)
                closed = true
                for _, ticket in pairs(pending) do
                    ticket.retire()
                end
                return dispatchers.on_exit(...)
            end,
        })
        local rpc = type(cmd) == "function" and cmd(hooks, config)
            ---@diagnostic disable-next-line: param-type-mismatch -- `cmd` is a list here; the `and/or` hides that.
            or vim.lsp.rpc.start(cmd, hooks, {
                -- Mirror native: nightly also falls back to root_dir.
                cwd = config.cmd_cwd or (vim.fn.has "nvim-0.13" == 1 and config.root_dir or nil),
                env = config.cmd_env,
                detached = config.detached,
            })
        local request, notify = rpc.request, rpc.notify

        rpc.request = function(method, params, callback, on_reply)
            if method ~= "textDocument/completion" then
                return request(method, params, callback, on_reply)
            end
            -- Send-time eligibility: a native trigger timer may already be queued
            -- when the route changes, and manual get() bypasses autotrigger.
            local owner = request_buf(params.textDocument.uri)
            if not opts.sources.lsp or (owner and (excluded(owner) or M.route_of(owner) ~= "language")) then
                return false
            end
            watch(api.nvim_get_current_buf())
            local ticket = { snapshot = snapshot() }
            ticket.retire = function()
                ticket.dead = true
                active[ticket] = nil
                if ticket.id then
                    pending[ticket.id] = nil
                end
            end
            active[ticket] = true
            local ok, id = request(method, params, function(...)
                local valid = not closed and not rpc.is_closing() and current(ticket)
                ticket.retire()
                if valid then
                    local err, result, ctx = ...
                    callback(err, skip_kinds(result), ctx)
                end
            end, function(rid)
                -- Native pending-request accounting must always run, even for dropped replies.
                if on_reply then
                    on_reply(rid)
                end
            end)
            if not ok then
                ticket.retire()
            elseif not ticket.dead then
                ticket.id = id
                pending[id] = ticket
            end
            return ok, id
        end

        rpc.notify = function(method, params)
            if method == "$/cancelRequest" and pending[params.id] then
                pending[params.id].retire()
            end
            return notify(method, params)
        end
        return rpc
    end
    wrappers[cmd] = wrapper
    is_wrapper[wrapper] = true
    return wrapper
end

--- Wrap the resolved `cmd` of each named config. A missing executable is left alone, because
--- native only skips it quietly while `cmd` is a list.
---@param names string|string[]
function M.decorate(names)
    for _, name in ipairs(vim._ensure_list(names)) do
        local ok, config = pcall(function()
            return vim.lsp.config[name]
        end)
        local cmd = ok and config and config.cmd
        if cmd and not is_wrapper[cmd] and (type(cmd) == "function" or vim.fn.executable(cmd[1]) == 1) then
            vim.lsp.config(name, { cmd = M.wrap_cmd(cmd) })
        end
    end
end

local enable, hooked = vim.lsp.enable, false

--- Make `vim.lsp.enable` decorate configs first; idempotent. Clients started earlier are not retrofitted.
function M.hook_enable()
    if hooked then
        return
    end
    hooked = true
    vim.lsp.enable = function(name, on)
        if on ~= false then
            M.decorate(name)
        end
        return enable(name, on)
    end
end

--- Byte index of the quote left open at the end of `prefix`, or nil.
---@param prefix string
---@return integer?
local function open_quote(prefix)
    local quote
    local i = 1
    while i <= #prefix do
        local c = prefix:sub(i, i)
        if quote then
            if c == "\\" then
                i = i + 1
            elseif c == quote then
                quote = nil
            end
        elseif c == '"' or c == "'" then
            quote = c
        end
        i = i + 1
    end
    return quote and prefix:match("^.*()" .. quote) or nil
end

--- Path being typed at the end of `prefix`: `dir` up to the last slash, `start` the 0-based
--- byte column of the final segment.
---@param prefix string
---@return { dir: string, start: integer }?
local function path_context(prefix)
    local quote_at = open_quote(prefix)
    local token, token_start
    if quote_at then
        token_start = quote_at + 1
        token = prefix:sub(token_start)
    else
        token = prefix:match "[^%s%(%)=,;<>%[%]{}'\"`|]*$"
        token_start = #prefix - #token + 1
    end
    -- `$VAR`, globs and `//` (comments, URLs) are never paths.
    if token:find "[%$%*%?]" or token:find("//", 1, true) then
        return nil
    end
    ---@type integer|boolean|nil
    local shaped = token:find "^%./" or token:find "^%.%./" or token:find "^~/" or token:find "^/"
    if not shaped then
        -- Numeric first segments (`3/4`) are arithmetic. TODO: an unquoted `word/` is a path only if
        -- `word` is a directory in the cwd, so `a/b` still misroutes when `a/` exists; treesitter would fix it.
        local first = not quote_at and token:match "^([%w_%.%-@+]+)/"
        shaped = (quote_at and token:find "/" or (first and vim.fn.isdirectory(vim.fn.getcwd() .. "/" .. first) == 1))
            and not token:find "^[%d%.]+/"
    end
    if not shaped then
        return nil
    end
    local slash = token:match "^.*()/"
    return { dir = token:sub(1, slash), start = token_start - 1 + slash }
end

local function cursor_context()
    local col = api.nvim_win_get_cursor(0)[2]
    return path_context(api.nvim_get_current_line():sub(1, col))
end

--- `'complete'` `F{func}` source. Filters itself because `completeopt=fuzzy` only ranks items.
---@param findstart integer
---@param base string
---@return integer|table
function M.path(findstart, base)
    local ctx = cursor_context()
    if findstart == 1 then
        return ctx and ctx.start or -3
    end
    if not ctx then
        return {}
    end
    local dir = ctx.dir
    if dir:sub(1, 2) == "~/" then
        dir = vim.fs.joinpath(vim.env.HOME or "", dir:sub(3))
    elseif dir:sub(1, 1) ~= "/" then
        dir = vim.fs.joinpath(vim.fn.getcwd(), dir)
    end
    if dir:sub(-1) ~= "/" then
        dir = dir .. "/"
    end
    local items = {}
    -- vim.fs.dir throws for missing or unreadable directories.
    pcall(function()
        for name, kind in vim.fs.dir(dir) do
            if base:sub(1, 1) == "." or name:sub(1, 1) ~= "." then
                local is_dir = kind == "directory" or (kind == "link" and vim.fn.isdirectory(dir .. name) == 1)
                local kind = is_dir and "Folder" or "File"
                items[#items + 1] = {
                    word = is_dir and name .. "/" or name,
                    kind = glyphs[kind],
                    kind_hlgroup = glyphs[kind] and "MicroKind" .. kind,
                    menu = glyphs[kind] and "[path]",
                }
            end
        end
    end)
    if base ~= "" then
        items = vim.fn.matchfuzzy(items, base, { key = "word" })
    end
    return { words = items, refresh = "always" }
end

local ROUTE_VAR = "micro_completion_route"
-- True while the module itself writes options, so its own OptionSet events do not invalidate.
local tuning = false

---@param buf integer
---@return micro.completion.Route
function M.route_of(buf)
    return vim.b[buf][ROUTE_VAR] or "language"
end

local function from_lsp(item)
    return vim.tbl_get(item, "user_data", "nvim", "lsp", "client_id") ~= nil
end

-- Fuzzy scores for the current sort, keyed by item; reset when the typed text changes.
local scores = setmetatable({}, { __mode = "k" })
local scored_for

--- Native fuzzy score of the item against the keyword typed before the cursor (0 if none).
local function rank_score(item)
    local line = api.nvim_get_current_line():sub(1, api.nvim_win_get_cursor(0)[2])
    local typed = line:sub(vim.fn.match(line, "\\k*$") + 1)
    if typed ~= scored_for then
        scores, scored_for = setmetatable({}, { __mode = "k" }), typed
    end
    if scores[item] == nil then
        local found = typed ~= "" and vim.fn.matchfuzzypos({ item.word }, typed)[3][1]
        scores[item] = found or 0
    end
    return scores[item]
end

--- Native `cmp` comparator implementing candidate ranking: LSP items before buffer words, then
--- fuzzy match quality, then the server's order (sortText, label) or the word. `complete()` then
--- drops the later buffer copy of a repeated word, since only LSP items set `dup`.
local function lsp_first(a, b)
    local la, lb = from_lsp(a), from_lsp(b)
    if la ~= lb then
        return la
    end
    local sa, sb = rank_score(a), rank_score(b)
    if sa ~= sb then
        return sa > sb
    end
    if la then
        local ia, ib = a.user_data.nvim.lsp.completion_item, b.user_data.nvim.lsp.completion_item
        local ka = (ia.sortText or "") ~= "" and ia.sortText or ia.label
        local kb = (ib.sortText or "") ~= "" and ib.sortText or ib.label
        if ka ~= kb then
            return ka < kb
        end
    end
    return a.word < b.word
end

--- Native `convert`: swap the kind name for its glyph. Color items keep native swatches.
local function decorate_kind(item)
    local name = vim.lsp.protocol.CompletionItemKind[item.kind]
    if not glyphs[name] or name == "Color" then
        return {}
    end
    return { kind = glyphs[name], kind_hlgroup = "MicroKind" .. name }
end

--- Apply the route for the cursor (or `wanted`). Native autotrigger hooks are installed once per
--- buffer handle, so a switch disables native completion and re-enables it for language only.
---@param buf integer
---@param wanted? micro.completion.Route
---@param force? boolean Re-apply even if the route is unchanged.
local function route(buf, wanted, force)
    if not api.nvim_buf_is_valid(buf) then
        return
    end
    if excluded(buf) then
        wanted = "disabled"
    elseif not wanted or wanted == "disabled" then
        local ctx = buf == api.nvim_get_current_buf() and cursor_context()
        wanted = ctx and "path" or "language"
    end
    if wanted == "path" and not opts.sources.path then
        wanted = "language"
    end
    local clients = opts.sources.lsp and vim.lsp.get_clients { bufnr = buf, method = "textDocument/completion" } or {}
    local stored = vim.b[buf][ROUTE_VAR]
    -- Stay unrouted until a completion client exists, so servers that register completion
    -- dynamically (after LspAttach) still get routed.
    local waiting = opts.sources.lsp and wanted == "language" and #clients == 0 and "language"
    if (stored or waiting) == wanted and not force then
        return
    end
    M.invalidate()
    for _, client in ipairs(clients) do
        vim.lsp.completion.enable(false, client.id, buf)
    end
    vim.b[buf][ROUTE_VAR] = wanted
    if wanted == "disabled" then
        -- Leave the buffer's own omnifunc and complete untouched.
        tuning = true
        pcall(function()
            vim.bo[buf].autocomplete = false
        end)
        tuning = false
        return
    end
    vim.bo[buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    if wanted == "path" then
        vim.bo[buf].complete = "Fv:lua.require'micro.completion'.path"
    else
        local flags = {}
        if opts.sources.buffer then
            flags[#flags + 1] = "."
        end
        if opts.sources.lsp then
            flags[#flags + 1] = "o"
        end
        vim.bo[buf].complete = table.concat(flags, ",")
        for _, client in ipairs(clients) do
            vim.lsp.completion.enable(true, client.id, buf, {
                autotrigger = true,
                cmp = opts.prefer_lsp and lsp_first or nil,
                -- convert/cmp are stored once per buffer handle, so pass them on every enable.
                convert = next(glyphs) and decorate_kind or nil,
            })
        end
    end
end

--- Native `'autocomplete'` has no minimum word length, so enable it only once the keyword is long
--- enough. TODO: 0.12.5 ignores `'autocompletedelay'`, so the debounce only works on nightly.
---@param buf integer
---@param prefix string Line text up to and including the character being inserted.
local function tune(buf, prefix)
    if buf ~= api.nvim_get_current_buf() or M.route_of(buf) == "disabled" then
        return
    end
    local path = M.route_of(buf) == "path"
    local long_enough = vim.fn.strchars(vim.fn.matchstr(prefix, "\\k*$")) >= opts.min_word_length
    tuning = true
    -- pcall: the flag must be reset even if an assignment throws, or invalidation stays muted.
    pcall(function()
        vim.bo[buf].autocomplete = path or long_enough
        vim.o.autocompletedelay = path and 0 or opts.debounce
    end)
    tuning = false
end

local function tune_here(buf)
    local col = api.nvim_win_get_cursor(0)[2]
    tune(buf, api.nvim_get_current_line():sub(1, col))
end

--- Expr-mapping helper: route for the cursor, then return `<C-n>`, or "" when nothing should open.
---@return string
function M.trigger()
    local buf = api.nvim_get_current_buf()
    if vim.fn.pumvisible() == 1 then
        return ""
    end
    route(buf)
    return M.route_of(buf) == "disabled" and "" or "<C-n>"
end

---@param user_opts? micro.completion.Opts
function M.setup(user_opts)
    opts = vim.tbl_deep_extend("force", defaults, user_opts or {})
    glyphs = {}
    local overrides = type(opts.icons) == "table" and opts.icons or {}
    for name, spec in pairs(opts.icons and KINDS or {}) do
        glyphs[name] = overrides[name] or spec[1]
    end
    local function kind_highlights()
        require("micro.kinds").highlights(vim.tbl_keys(glyphs))
    end
    kind_highlights()
    M.hook_enable()
    api.nvim_clear_autocmds { group = group }
    M.invalidate()
    -- `:colorscheme` runs `:hi clear`, which drops default links.
    api.nvim_create_autocmd("ColorScheme", { group = group, callback = kind_highlights })

    vim.opt.completeopt:append { "menu", "menuone", "noselect", "popup", "fuzzy" }

    api.nvim_create_autocmd({ "InsertLeave", "BufLeave", "WinLeave", "CompleteDone", "LspDetach" }, {
        group = group,
        callback = M.invalidate,
    })
    -- 'autocompletedelay' is global; a path context sets it to 0, so restore it on leaving insert.
    api.nvim_create_autocmd("InsertLeave", {
        group = group,
        callback = function()
            vim.o.autocompletedelay = opts.debounce
        end,
    })
    api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = { "complete", "omnifunc", "autocomplete", "iskeyword" },
        callback = function()
            if not tuning then
                M.invalidate()
            end
        end,
    })
    api.nvim_create_autocmd("CompleteChanged", {
        group = group,
        callback = function()
            if vim.fn.complete_info({ "selected" }).selected >= 0 then
                M.invalidate()
            end
        end,
    })

    api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client:supports_method("textDocument/completion", ev.buf) then
                route(ev.buf, nil, true)
                tune_here(ev.buf)
            end
        end,
    })
    api.nvim_create_autocmd({ "BufEnter", "FileType", "InsertEnter", "TextChangedI", "CursorMovedI" }, {
        group = group,
        callback = function(ev)
            route(ev.buf)
            tune_here(ev.buf)
        end,
    })
    -- Classify the character about to be inserted so the route is switched before
    -- native triggers fire for it.
    api.nvim_create_autocmd("InsertCharPre", {
        group = group,
        callback = function(ev)
            local col = api.nvim_win_get_cursor(0)[2]
            local prospective = api.nvim_get_current_line():sub(1, col) .. vim.v.char
            route(ev.buf, path_context(prospective) and "path" or "language")
            tune(ev.buf, prospective)
        end,
    })
end

return M
