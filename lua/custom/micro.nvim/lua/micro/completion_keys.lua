-- Convenience keys for native completion. Kept apart from `micro.completion` (the backend):
-- these only call its public `trigger()`/`invalidate()` and otherwise return native keys.
-- Tab/snippet interaction is the delicate part; see docs/specs/completion/spec.md.
local M = {}

local function menu_open()
    return vim.fn.pumvisible() == 1
end

local function selected()
    return menu_open() and vim.fn.complete_info({ "selected" }).selected >= 0
end

-- Tab / Shift-Tab: open menu, then snippet placeholders, then the normal key.
local function tab(direction, native_key, menu_key)
    return function()
        if menu_open() then
            return menu_key
        end
        if vim.snippet.active { direction = direction } then
            return ("<Cmd>lua vim.snippet.jump(%d)<CR>"):format(direction)
        end
        return native_key
    end
end

-- Scroll the native documentation popup, only while it is showing. The window id comes from
-- complete_info({"selected"}); scrolling is scheduled because normal commands are not
-- allowed while an <expr> mapping is evaluated.
local function scroll(native_key, scroll_key)
    return function()
        local win = vim.fn.complete_info({ "selected" }).preview_winid
        if win and vim.api.nvim_win_is_valid(win) then
            vim.schedule(function()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_call(win, function()
                        vim.cmd.normal { args = { vim.keycode(scroll_key) }, bang = true }
                    end)
                end
            end)
            return ""
        end
        return native_key
    end
end

function M.setup()
    local completion = require "micro.completion"
    local expr = { expr = true, silent = true }
    local function map(modes, lhs, fn, desc)
        vim.keymap.set(modes, lhs, fn, vim.tbl_extend("force", expr, { desc = desc }))
    end

    map("i", "<C-Space>", completion.trigger, "Completion: open")
    map("i", "<CR>", function()
        return selected() and "<C-y>" or "<CR>"
    end, "Completion: accept selected, else newline")
    map({ "i", "s" }, "<Tab>", tab(1, "<Tab>", "<C-n>"), "Completion/snippet: next")
    map({ "i", "s" }, "<S-Tab>", tab(-1, "<S-Tab>", "<C-p>"), "Completion/snippet: previous")
    map("i", "<C-e>", function()
        -- Also expires an in-flight request when no menu is open yet.
        completion.invalidate()
        return "<C-e>"
    end, "Completion: cancel")
    map("i", "<C-b>", scroll("<C-b>", "<C-u>"), "Completion: scroll docs up")
    map("i", "<C-f>", scroll("<C-f>", "<C-d>"), "Completion: scroll docs down")
end

return M
