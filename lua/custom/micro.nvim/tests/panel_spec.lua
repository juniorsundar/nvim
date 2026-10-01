local Editor = require "tests.support.editor"

describe("micro.panel", function()
    local ed

    before_each(function()
        ed = Editor.new()
        ed:lua [[
            _G.panel = require "micro.panel"
            _G.float = { relative = "editor", row = 0, col = 0, width = 10, height = 1 }
        ]]
    end)
    after_each(function()
        ed:close()
    end)

    it("reuses the window for a key and replaces its read-only, tagged buffer content", function()
        local r = ed:lua [[
            local w1, b1 = panel.open("k", { "one" }, float)
            local w2, b2 = panel.open("k", { "two", "lines" }, vim.tbl_extend("force", float, { height = 2 }))
            return {
                same = w1 == w2 and b1 == b2,
                lines = vim.api.nvim_buf_get_lines(b2, 0, -1, false),
                height = vim.api.nvim_win_get_height(w2),
                tag = vim.b[b2].micro_panel,
                modifiable = vim.bo[b2].modifiable,
                current = vim.api.nvim_get_current_win() ~= w2,
            }
        ]]
        assert.same(
            { same = true, lines = { "two", "lines" }, height = 2, tag = "k", modifiable = false, current = true },
            r
        )
    end)

    it("close removes the window and wipes the buffer", function()
        local r = ed:lua [[
            local w, b = panel.open("k", { "x" }, float)
            panel.close "k"
            return { win = vim.api.nvim_win_is_valid(w), buf = vim.api.nvim_buf_is_valid(b), get = panel.get "k" == nil }
        ]]
        assert.same({ win = false, buf = false, get = true }, r)
    end)

    it("forgets a panel closed by hand and opens a fresh one", function()
        local r = ed:lua [[
            local w1 = panel.open("k", { "x" }, float)
            vim.api.nvim_win_close(w1, true)
            local gone = panel.get "k" == nil
            local w2 = panel.open("k", { "y" }, float)
            return { gone = gone, fresh = w2 ~= w1 and vim.api.nvim_win_is_valid(w2) }
        ]]
        assert.same({ gone = true, fresh = true }, r)
    end)

    it("opens splits from a split config", function()
        local r = ed:lua [[
            local w = panel.open("s", { "a", "b" }, { split = "below", win = -1, height = 2 })
            return { split = vim.api.nvim_win_get_config(w).relative == "", wins = #vim.api.nvim_tabpage_list_wins(0) }
        ]]
        assert.same({ split = true, wins = 2 }, r)
    end)

    it("closes with its parent window", function()
        ed:lua [[
            vim.cmd.vsplit()
            _G.parent = vim.api.nvim_get_current_win()
            _G.w = panel.open("p", { "x" }, vim.tbl_extend("force", float, { relative = "win", win = parent }), { parent = parent })
            vim.api.nvim_win_close(parent, true)
        ]]
        ed:wait "not vim.api.nvim_win_is_valid(_G.w) and _G.panel.get('p') == nil"
    end)
end)
