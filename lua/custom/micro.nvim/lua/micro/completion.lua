-- Backend-only enhancement of native completion (see docs/specs/completion/spec.md).
-- Native Neovim owns the popup, matching, LSP requests, resolution, snippets and
-- acceptance. This module adds a lifecycle guard that drops stale
-- `textDocument/completion` replies before they reach native completion.
local M = {}

local api = vim.api
local epoch = 0
-- ticket -> true; weak so abandoned tickets never leak.
local active = setmetatable({}, { __mode = "k" })
-- original cmd -> wrapper, and wrapper -> true, for idempotent decoration.
local wrappers = setmetatable({}, { __mode = "k" })
local is_wrapper = setmetatable({}, { __mode = "k" })
local watched = {}
local group = api.nvim_create_augroup("micro_completion", { clear = true })

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
        autocomplete = vim.bo.autocomplete,
        iskeyword = vim.bo.iskeyword,
        uri = vim.uri_from_bufnr(0),
    }
end

local function current(ticket)
    local s = ticket.snapshot
    if ticket.dead or epoch ~= s.epoch then
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
        and vim.bo.autocomplete == s.autocomplete
        and vim.bo.iskeyword == s.iskeyword
        and vim.uri_from_bufnr(0) == s.uri
        and vim.fn.complete_info({ "selected" }).selected < 0
end

--- Decorate a `vim.lsp.Config.cmd` (list or function factory). Must run before the
--- client starts; idempotent. Only `textDocument/completion` replies are filtered.
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
                cwd = config.cmd_cwd,
                env = config.cmd_env,
                detached = config.detached,
            })
        local request, notify = rpc.request, rpc.notify

        rpc.request = function(method, params, callback, on_reply)
            if method ~= "textDocument/completion" then
                return request(method, params, callback, on_reply)
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
                    callback(...)
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

function M.setup(_)
    api.nvim_clear_autocmds { group = group }
    M.invalidate()

    vim.opt.completeopt:append { "menu", "menuone", "noselect", "popup", "fuzzy" }

    api.nvim_create_autocmd({ "InsertLeave", "BufLeave", "WinLeave", "CompleteDone", "LspDetach" }, {
        group = group,
        callback = M.invalidate,
    })
    api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = { "complete", "omnifunc", "autocomplete", "iskeyword" },
        callback = M.invalidate,
    })
    api.nvim_create_autocmd("CompleteChanged", {
        group = group,
        callback = function()
            if vim.fn.complete_info({ "selected" }).selected >= 0 then
                M.invalidate()
            end
        end,
    })

    -- Language context: LSP candidates and current-buffer words coexist natively.
    api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if not client or not client:supports_method("textDocument/completion", ev.buf) then
                return
            end
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
            vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
            vim.bo[ev.buf].complete = ".,o"
            vim.bo[ev.buf].autocomplete = true
        end,
    })
end

return M
