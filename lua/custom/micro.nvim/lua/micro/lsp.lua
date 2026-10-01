-- Keyed LSP requests at a window's cursor. Each key holds at most one live request:
-- a new request (or `cancel`) for the same key supersedes the old one, and replies
-- belonging to a superseded request are dropped.
local M = {}

---@type table<string, { gen: integer, timer?: uv.uv_timer_t, cancel?: fun() }>
local slots = {}

local function live(win, buf)
    return vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf
end

--- Cancel the pending request and debounce timer for `key`; its replies are dropped.
---@param key string
function M.cancel(key)
    local s = slots[key]
    if not s then
        return
    end
    s.gen = s.gen + 1
    if s.timer then
        s.timer:stop()
        s.timer:close()
        s.timer = nil
    end
    if s.cancel then
        s.cancel()
        s.cancel = nil
    end
end

--- Send `method` for the buffer shown in `win` to every client that supports it.
--- `params_fn(client, buf)` builds each client's params; use `client.offset_encoding`
--- for positions. `handler(err, result, ctx)` sees replies in arrival order until it
--- returns true (reply consumed). It never runs once the request is superseded or
--- `win` no longer shows the buffer. No capable client: nothing is sent.
---@param key string
---@param win integer
---@param method string
---@param params_fn fun(client: vim.lsp.Client, buf: integer): table
---@param handler fun(err: lsp.ResponseError?, result: any, ctx: lsp.HandlerContext): boolean?
---@param opts? { debounce?: integer } delay in ms before sending
function M.request(key, win, method, params_fn, handler, opts)
    M.cancel(key)
    local s = slots[key] or { gen = 0 }
    slots[key] = s
    local gen = s.gen
    win = win == 0 and vim.api.nvim_get_current_win() or win
    local buf = vim.api.nvim_win_get_buf(win)

    local function send()
        if s.gen ~= gen then
            return
        end
        if s.timer then
            s.timer:close()
            s.timer = nil
        end
        if not live(win, buf) or #vim.lsp.get_clients { bufnr = buf, method = method } == 0 then
            return
        end
        local done = false
        local _, cancel = vim.lsp.buf_request(buf, method, params_fn, function(err, result, ctx)
            if done or s.gen ~= gen or not live(win, buf) then
                return
            end
            done = handler(err, result, ctx) == true
        end, function() end)
        s.cancel = cancel
    end

    local ms = opts and opts.debounce
    if not ms or ms <= 0 then
        return send()
    end
    s.timer = assert(vim.uv.new_timer())
    s.timer:start(ms, 0, vim.schedule_wrap(send))
end

return M
