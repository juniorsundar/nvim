-- Keyed LSP requests: a new request or `cancel` on a key supersedes it, and superseded replies are dropped.
local M = {}

---@class micro.lsp.Cursor
---@field win integer
---@field buf integer
---@field pos integer[] (1,0)-indexed cursor.
---@field tick integer
---@field uri string

---@alias micro.lsp.Handler fun(err: lsp.ResponseError?, result: any, ctx: lsp.HandlerContext): boolean?

---@type table<string, { gen: integer, timer?: uv.uv_timer_t, cancel?: fun(), cursor?: micro.lsp.Cursor }>
local slots = {}

local function live(win, buf, cursor)
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
        return false
    end
    return not cursor
        or (
            vim.api.nvim_get_current_win() == win
            and vim.api.nvim_buf_get_changedtick(buf) == cursor.tick
            and vim.uri_from_bufnr(buf) == cursor.uri
            and vim.deep_equal(vim.api.nvim_win_get_cursor(win), cursor.pos)
        )
end

---@param key string
function M.cancel(key)
    local s = slots[key]
    if not s then
        return
    end
    s.gen = s.gen + 1
    s.cursor = nil
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

--- Cancel `key` and forget it, for per-buffer keys whose buffer is gone.
---@param key string
function M.forget(key)
    M.cancel(key)
    -- Superseded callbacks hold their own slot table and still see the bumped generation.
    slots[key] = nil
end

---@param cursor? micro.lsp.Cursor
local function request(key, win, method, params_fn, handler, opts, cursor)
    M.cancel(key)
    local s = slots[key] or { gen = 0 }
    slots[key] = s
    s.cursor = cursor
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
        if not live(win, buf, cursor) or #vim.lsp.get_clients { bufnr = buf, method = method } == 0 then
            return
        end
        local done = false
        local _, cancel = vim.lsp.buf_request(buf, method, params_fn, function(err, result, ctx)
            if done or s.gen ~= gen or not live(win, buf, cursor) then
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

--- Send `method` to every capable client of the buffer in `win`. `handler` sees replies in arrival
--- order until it returns true, and never after the request is superseded or `win` changes buffer.
---@param key string
---@param win integer
---@param method string
---@param params_fn fun(client: vim.lsp.Client, buf: integer): table Use `client.offset_encoding` for positions.
---@param handler micro.lsp.Handler
---@param opts? { debounce?: integer } Delay in ms before sending.
function M.request(key, win, method, params_fn, handler, opts)
    return request(key, win, method, params_fn, handler, opts)
end

--- Like `request`, at the cursor; moving, editing or leaving the window expires it.
---@param key string
---@param win integer
---@param method string
---@param handler micro.lsp.Handler
---@param opts? { debounce?: integer }
function M.request_cursor(key, win, method, handler, opts)
    win = win == 0 and vim.api.nvim_get_current_win() or win
    local buf = vim.api.nvim_win_get_buf(win)
    local cursor = {
        win = win,
        buf = buf,
        pos = vim.api.nvim_win_get_cursor(win),
        tick = vim.api.nvim_buf_get_changedtick(buf),
        uri = vim.uri_from_bufnr(buf),
    }
    return request(key, win, method, function(client)
        return vim.lsp.util.make_position_params(win, client.offset_encoding)
    end, handler, opts, cursor)
end

vim.api.nvim_create_autocmd({
    "CursorMoved",
    "CursorMovedI",
    "TextChanged",
    "TextChangedI",
    "TextChangedP",
    "WinLeave",
    "BufLeave",
    "WinClosed",
    "BufFilePost",
}, {
    group = vim.api.nvim_create_augroup("MicroLsp", { clear = true }),
    callback = function(ev)
        for key, s in pairs(slots) do
            local cursor = s.cursor
            if cursor then
                local leaving = (ev.event == "WinLeave" and cursor.win == vim.api.nvim_get_current_win())
                    or (ev.event == "BufLeave" and cursor.buf == ev.buf)
                -- A consumer may already have requested the new cursor context in this event.
                if leaving or not live(cursor.win, cursor.buf, cursor) then
                    M.cancel(key)
                end
            end
        end
    end,
})

return M
