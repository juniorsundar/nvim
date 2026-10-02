-- One reusable transient window per key. `vim.b.micro_panel` marks panel buffers so other features can skip them.
local M = {}

---@type table<string, { win: integer, buf: integer, parent?: integer }>
local panels = {}

---@param key string
---@return integer? win, integer? buf
function M.get(key)
    local p = panels[key]
    if p and vim.api.nvim_win_is_valid(p.win) then
        return p.win, p.buf
    end
    panels[key] = nil
end

---@param key string
function M.close(key)
    local win = M.get(key)
    panels[key] = nil
    if win then
        pcall(vim.api.nvim_win_close, win, true)
    end
end

--- Show read-only `lines` for `key`, reusing and reconfiguring an open panel.
---@param key string
---@param lines string[]
---@param config vim.api.keyset.win_config
---@param opts? { parent?: integer } Close the panel when this window closes.
---@return integer win, integer buf
function M.open(key, lines, config, opts)
    local win, buf = M.get(key)
    if win then
        vim.api.nvim_win_set_config(win, config)
    else
        buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].bufhidden = "wipe"
        vim.b[buf].micro_panel = key
        win = vim.api.nvim_open_win(buf, false, config)
        panels[key] = { win = win, buf = buf, parent = opts and opts.parent }
    end
    ---@cast buf integer
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    return win, buf
end

vim.api.nvim_create_autocmd("WinClosed", {
    group = vim.api.nvim_create_augroup("MicroPanel", { clear = true }),
    callback = function(ev)
        local closed = tonumber(ev.match)
        for key, p in pairs(panels) do
            if p.parent == closed then
                -- Closing windows inside WinClosed can be refused; do it once it returns.
                vim.schedule(function()
                    if panels[key] == p then
                        M.close(key)
                    end
                end)
            end
        end
    end,
})

return M
