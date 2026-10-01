-- Backend-only enhancement of native completion (see docs/specs/completion/spec.md).
-- Native Neovim owns the popup, matching, LSP requests, resolution, snippets and
-- acceptance. This module adds a lifecycle guard that drops stale
-- `textDocument/completion` replies before they reach native completion.
local M = {}

-- sources: which candidate sources are used. `lsp` = language servers, `buffer` = words in the
-- current buffer, `path` = filesystem paths. A source set to false is never queried.
-- prefer_lsp: when a buffer word and an LSP item share the same word, show only the LSP item.
-- skip_kinds: LSP CompletionItemKind names to drop from server replies, e.g. { "Text" }.
local defaults = {
    min_word_length = 2,
    debounce = 80,
    prefer_lsp = true,
    skip_kinds = {},
    sources = { lsp = true, buffer = true, path = true },
}
local opts = vim.deepcopy(defaults)

local api = vim.api
local epoch = 0
-- ticket -> true; weak so abandoned tickets never leak.
local active = setmetatable({}, { __mode = "k" })
-- original cmd -> wrapper, and wrapper -> true, for idempotent decoration.
local wrappers = setmetatable({}, { __mode = "k" })
local is_wrapper = setmetatable({}, { __mode = "k" })
local watched = {}
local group = api.nvim_create_augroup("micro_completion", { clear = true })

local excluded_filetypes = { refer_input = true, refer_results = true }

--- Buffers that never get completion: refer prompt/results, any non-file buffer,
--- and anything that opts out with `vim.b.completion = false`.
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

--- Expire every in-flight completion reply (e.g. after the user dismisses with no menu open).
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
    -- ponytail: only keyword-prefix extension is accepted; other edits expire the
    -- reply instead of rebasing native replacement ranges.
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

-- Existing buffer whose URI is exactly `uri`, or nil. Never creates buffers.
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

--- Decorate a `vim.lsp.Config.cmd` (list or function factory). Must run before the
--- client starts; idempotent. Only `textDocument/completion` replies are filtered.
--- Remove items of the configured `skip_kinds` from a completion result (list or CompletionList).
--- Unknown kind names are ignored. Returns the result unchanged when nothing is skipped.
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

function M.wrap_cmd(cmd)
    if is_wrapper[cmd] then
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

--- Decorate the resolved `cmd` of the named configs, so each client is guarded from its
--- first request. Skips configs whose executable is missing: native silently skips those
--- only while `cmd` is a list, and a function `cmd` would turn that into a startup error.
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

--- The one shared decoration point: every server the config enables is decorated first.
--- Idempotent. Servers enabled before this runs are not retrofitted (restart them).
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

---------------------------------------------------------------------------
-- Filesystem source (path context)
---------------------------------------------------------------------------

-- Text after the last unterminated quote before the end of `prefix`, if any.
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

--- Returns { dir = "src/", start = <0-based byte col of final segment> } when the text
--- before the cursor ends inside a path, else nil. Paths are `./`, `../`, `~/`, absolute
--- `/` and relative `name/` forms. Spaces are allowed only inside an open quote.
--- `$VAR` and glob characters never form a path; `//` (comments, URLs) does not either.
--- ponytail: an unquoted `word/` is always a path (needed for `src/`), so `a/b` in prose or a
--- comment also routes to paths; add lexical (treesitter) context if that proves annoying.
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
    if token:find "[%$%*%?]" or token:find("//", 1, true) then
        return nil
    end
    local shaped = token:find "^%./" or token:find "^%.%./" or token:find "^~/" or token:find "^/"
    if not shaped then
        -- relative `src/...`; unquoted tokens must be a plain word chain, quoted may hold spaces
        -- A purely numeric first segment (`1./2`, `3/4`) is arithmetic, not a path.
        shaped = (quote_at and token:find "/" or token:find "^[%w_%.%-@+]+/") and not token:find "^[%d%.]+/"
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

--- `'complete'` function source (`F{func}`): enumerate, then fuzzy-filter, because
--- `completeopt=fuzzy` ranks but never removes unrelated candidates.
function M.path(findstart, base)
    local ctx = cursor_context()
    if findstart == 1 then
        return ctx and ctx.start or -3
    end
    if not ctx then
        return {}
    end
    -- Relative paths resolve from the window's cwd (respects :lcd/:tcd), not the buffer's directory.
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
                items[#items + 1] = { word = is_dir and name .. "/" or name }
            end
        end
    end)
    if base ~= "" then
        items = vim.fn.matchfuzzy(items, base, { key = "word" })
    end
    return { words = items, refresh = "always" }
end

---------------------------------------------------------------------------
-- Routing
---------------------------------------------------------------------------

local ROUTE_VAR = "micro_completion_route"
-- True while the module itself writes options, so its own OptionSet events do not invalidate.
local tuning = false

function M.route_of(buf)
    return vim.b[buf][ROUTE_VAR] or "language"
end

--- Switch a buffer between "language" (LSP + buffer words) and "path" (filesystem only).
--- Native autotrigger hooks are installed once per buffer handle, so changing route
--- means disabling native LSP completion and re-enabling it only for language.
local function from_lsp(item)
    return vim.tbl_get(item, "user_data", "nvim", "lsp", "client_id") ~= nil
end

--- Sort comparator for native `cmp`: LSP items first. `complete()` drops a later item whose word
--- repeats an earlier one unless it sets `dup` (LSP items do), so the buffer copy disappears.
local function lsp_first(a, b)
    return from_lsp(a) and not from_lsp(b)
end

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
    -- With LSP on, a buffer with no completion-capable client yet stays unrouted, so a server
    -- that registers completion dynamically (after LspAttach) is routed once it has.
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
        -- Leave the buffer's own omnifunc/complete alone; just stop automatic completion.
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
            })
        end
    end
end

--- Native `'autocomplete'` has no minimum word length, so the module owns the switch:
--- in a language context it is on only once the word before the cursor (including the
--- character being inserted) reaches `min_word_length`. Native `'autocompletedelay'` is
--- the debounce (ponytail: 0.12.5 ignores that option, so the debounce only takes effect on
--- nightly; add a module timer if stable needs it). Paths open at once. Server trigger characters use native LSP autotrigger,
--- which does not depend on `'autocomplete'`.
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

--- Manual completion for an expr mapping: route the buffer first (so a path or language
--- context is chosen for the cursor as it is now, and an excluded buffer becomes "disabled"),
--- then return the native key that opens it. Native `<C-n>` ignores the word threshold.
--- Returns "" when nothing should open.
function M.trigger()
    local buf = api.nvim_get_current_buf()
    if vim.fn.pumvisible() == 1 then
        return ""
    end
    route(buf)
    return M.route_of(buf) == "disabled" and "" or "<C-n>"
end

function M.setup(user_opts)
    opts = vim.tbl_deep_extend("force", defaults, user_opts or {})
    M.hook_enable()
    api.nvim_clear_autocmds { group = group }
    M.invalidate()

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
    -- `vim.b.completion` is a plain variable with no event, so re-check on the events
    -- that follow most changes to it; the transport gate covers requests in between.
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
