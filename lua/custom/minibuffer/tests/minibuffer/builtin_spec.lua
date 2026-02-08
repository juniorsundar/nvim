local builtin = require "minibuffer.providers.builtin"

describe("builtin.commands history cycling", function()
    local picker

    -- Helper to simulate keypress
    local function trigger_key(key)
        local handler = picker.opts.keymaps[key]
        -- Construct mock context as picker.lua does
        local context = {
            picker = picker,
            actions = picker.actions,
            -- parameters not strictly needed for this test logic, but good to have
            parameters = {
                original_win = picker.original_win,
                original_buf = picker.original_buf,
            },
        }
        handler(nil, context) -- selection is nil in our empty/no-match case
    end

    local function set_input(text)
        vim.api.nvim_buf_set_lines(picker.input_buf, 0, -1, false, { text })
        -- Important: Manually trigger the changedtick logic if needed,
        -- but vim.api.nvim_buf_set_lines updates changedtick automatically.
        -- We also update the cursor to simulate real typing
        vim.api.nvim_win_set_cursor(picker.ui.input_win, { 1, #text })
    end

    local function get_input()
        local lines = vim.api.nvim_buf_get_lines(picker.input_buf, 0, -1, false)
        return lines[1] or ""
    end

    before_each(function()
        vim.fn.histdel "cmd"
        vim.fn.histadd("cmd", "short")
        vim.fn.histadd("cmd", "longer command")
        vim.fn.histadd("cmd", "lua print('very long command that caused issues')")
        vim.fn.histadd("cmd", "duplicate")
        vim.fn.histadd("cmd", "duplicate")
    end)

    after_each(function()
        if picker then
            picker:close()
        end
    end)

    it("cycles backwards through history with <C-p>", function()
        picker = builtin.commands()

        -- Initial state
        assert.are.same("", get_input())

        trigger_key "<C-p>"
        assert.are.same("duplicate", get_input())

        trigger_key "<C-p>"
        assert.are.same("lua print('very long command that caused issues')", get_input())

        trigger_key "<C-p>"
        assert.are.same("longer command", get_input())

        trigger_key "<C-p>"
        assert.are.same("short", get_input())
    end)

    it("cycles forwards through history with <C-n>", function()
        picker = builtin.commands()

        trigger_key "<C-p>"
        trigger_key "<C-p>"
        trigger_key "<C-p>"
        assert.are.same("longer command", get_input())

        trigger_key "<C-n>"
        assert.are.same("lua print('very long command that caused issues')", get_input())
    end)

    it("resets cycling when input matches but user types", function()
        picker = builtin.commands()

        set_input "lo"
        -- Note: cycle_history checks changedtick.
        -- set_input increments changedtick.
        -- Next trigger_key should detect this change.

        trigger_key "<C-p>"
        assert.are.same("longer command", get_input()) -- "longer command" matches "lo"

        -- User types "sh"
        set_input "sh"

        -- Next trigger should reset and search from "sh"
        trigger_key "<C-p>"
        assert.are.same("short", get_input()) -- "short" matches "sh"
    end)

    it("handles the specific long entry bug scenario", function()
        picker = builtin.commands()

        -- Cycle to "lua print..."
        trigger_key "<C-p>" -- duplicate
        trigger_key "<C-p>" -- lua print...
        assert.are.same("lua print('very long command that caused issues')", get_input())

        -- Cycle again - should go to "longer command"
        trigger_key "<C-p>"
        assert.are.same("longer command", get_input())
    end)
end)
