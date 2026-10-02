local Editor = require "tests.support.editor"

local function R(l1, c1, l2, c2)
    return { start = { line = l1, character = c1 }, ["end"] = { line = l2, character = c2 } }
end
local function sym(name, kind, r, children)
    return { name = name, kind = kind, range = r, selectionRange = r, children = children }
end

describe("micro.breadcrumbs", function()
    local ed, root, log

    before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src", "p")
        vim.fn.writefile({ "function outer()", "  local x = 1", "end", "", "tail" }, root .. "/src/a.txt")
        vim.fn.writefile({ "other" }, root .. "/src/b.txt")
        log = root .. "/log"
        ed = Editor.new()
        ed:lua("vim.cmd.cd(...); vim.notify = function() end", root)
        ed:lua("vim.cmd.edit(...)", root .. "/src/a.txt")
    end)
    after_each(function()
        ed:close()
        vim.fn.delete(root, "rf")
    end)

    local NESTED = { sym("outer", 12, R(0, 0, 2, 3), { sym("x", 13, R(1, 2, 1, 13)) }) }

    -- Rendered winbar text of `win` (default current).
    local function bar(win)
        return ed:lua(
            [[
            local win = ... or vim.api.nvim_get_current_win()
            local s = vim.wo[win].winbar
            if s == "" then return "" end
            return vim.api.nvim_eval_statusline(s, { winid = win, use_winbar = true }).str
        ]],
            win
        )
    end
    local function wait_bar(pattern, win)
        ed:wait(
            ([[(function()
                local win = %s or vim.api.nvim_get_current_win()
                local s = vim.wo[win].winbar
                return s ~= "" and vim.api.nvim_eval_statusline(s, { winid = win, use_winbar = true }).str:find(%q, 1, true) ~= nil
            end)()]]):format(win or "nil", pattern),
            4000
        )
    end
    local function start(opts, name)
        ed:server(opts, name or "sym")
    end
    local function requests()
        return vim.fn.filereadable(log) == 1 and #vim.fn.readfile(log) or 0
    end
    local function enable()
        ed:lua [[require("micro.breadcrumbs").setup { show = true }]]
    end

    it("shows the path from the cwd and the symbol chain at the cursor", function()
        start { symbols = NESTED }
        ed:lua [[vim.api.nvim_win_set_cursor(0, { 2, 8 })]]
        enable()
        wait_bar "outer > "
        local K = ed:lua [[return vim.tbl_map(function(k) return k[1] end, require("micro.kinds").KINDS)]]
        assert.equals((" src > %s a.txt > %s outer > %s x"):format(K.File, K.Function, K.Variable), bar())
    end)

    it("follows the cursor without a new request while the buffer is unchanged", function()
        start { symbols = NESTED, log = log }
        ed:lua [[vim.api.nvim_win_set_cursor(0, { 2, 8 })]]
        enable()
        wait_bar "outer > "
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log))
        ed:sleep(400) -- let any debounced refresh fire before counting
        local sent = requests()
        ed:input "G"
        ed:wait [[vim.api.nvim_win_get_cursor(0)[1] == 5]]
        ed:wait(
            "not vim.api.nvim_eval_statusline(vim.wo.winbar, { use_winbar = true }).str:find('outer', 1, true)",
            1000
        )
        ed:input "gg"
        wait_bar "outer"
        assert.equals(sent, requests())
    end)

    it("refreshes symbols after the buffer changes", function()
        start { symbols = NESTED, log = log }
        enable()
        wait_bar "outer"
        ed:sleep(400) -- let any debounced refresh fire before counting
        local sent = requests()
        -- An edit that leaves the cursor in place, so only the change can trigger a fetch.
        ed:lua [[vim.api.nvim_buf_set_lines(0, 4, 5, false, { "changed" })]]
        ed:wait(("#vim.fn.readfile(%q) > %d"):format(log, sent), 4000)
    end)

    it("keeps the row on every window so switching windows never shifts the text", function()
        start { symbols = NESTED }
        enable()
        wait_bar "outer"
        local first = ed:lua "return vim.api.nvim_get_current_win()"
        ed:lua("vim.cmd 'vsplit'; vim.cmd.edit(...)", root .. "/src/b.txt")
        local row = ed:lua "return vim.fn.screenpos(0, 1, 1).row"
        ed:lua "vim.cmd 'wincmd p'"
        ed:lua "vim.cmd 'wincmd p'"
        assert.equals(row, ed:lua "return vim.fn.screenpos(0, 1, 1).row")
        assert.truthy(bar(first):find("outer", 1, true)) -- inactive window keeps its crumbs
    end)

    it("handles flat SymbolInformation replies", function()
        local uri = vim.uri_from_fname(root .. "/src/a.txt")
        start { symbols = { { name = "outer", kind = 12, location = { uri = uri, range = R(0, 0, 2, 3) } } } }
        ed:lua [[vim.api.nvim_win_set_cursor(0, { 2, 2 })]]
        enable()
        wait_bar "outer"
        assert.equals("", ed:lua "return vim.v.errmsg")
    end)

    it("escapes % in names", function()
        start { symbols = { sym("100% done", 15, R(0, 0, 4, 4)) } }
        enable()
        wait_bar "100% done"
        assert.equals("", ed:lua "return vim.v.errmsg")
    end)

    it("uses the client that has symbols when another replies empty first", function()
        start({ symbols = {}, reply_delays = { 10 } }, "fast_empty")
        start({ symbols = NESTED, reply_delays = { 300 } }, "slow_real")
        enable()
        wait_bar "outer"
    end)

    it("treats a range end as exclusive at a shared boundary", function()
        vim.fn.writefile({ "aaabbbb" }, root .. "/src/a.txt")
        ed:lua "vim.cmd.edit { bang = true }"
        start { symbols = { sym("first", 12, R(0, 0, 0, 3)), sym("second", 12, R(0, 3, 0, 7)) } }
        ed:lua [[vim.api.nvim_win_set_cursor(0, { 1, 3 })]]
        enable()
        wait_bar "second"
        assert.is_nil(bar():find("first", 1, true))
    end)

    it("uses SymbolKind names for icons and highlights", function()
        start { symbols = { sym("obj", 19, R(0, 0, 4, 4)) } } -- 19 = Object
        enable()
        wait_bar "obj"
        local glyph = ed:lua [[return require("micro.kinds").KINDS.Object[1] ]]
        assert.truthy(bar():find(glyph .. " obj", 1, true))
        assert.truthy(ed:lua("return vim.wo.winbar"):find("MicroKindObject", 1, true))
    end)

    it("shows only the path in buffers without a symbol server", function()
        enable()
        wait_bar "a.txt"
    end)

    it("leaves non-file buffers and a user's own winbar alone", function()
        ed:lua [[vim.o.winbar = "MY BAR"]]
        ed:lua [[require("micro.breadcrumbs").setup {}]]
        assert.equals("MY BAR", ed:lua "return vim.go.winbar")
        enable()
        wait_bar "a.txt"
        local file_win = ed:lua "return vim.api.nvim_get_current_win()"
        ed:lua "vim.cmd 'help help'"
        assert.equals("MY BAR", ed:lua "return vim.wo.winbar")
        ed:lua [[require("micro.breadcrumbs").disable()]]
        assert.equals("MY BAR", ed:lua("return vim.wo[...].winbar", file_win))
    end)

    it("disable removes the bars it set", function()
        start { symbols = NESTED }
        enable()
        wait_bar "outer"
        ed:lua [[require("micro.breadcrumbs").disable()]]
        assert.equals("", ed:lua "return vim.wo.winbar")
    end)

    it("asks a server that has no symbols only once per change", function()
        start { symbols = {}, log = log }
        enable()
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log))
        ed:sleep(400)
        local sent = requests()
        for _ = 1, 4 do
            ed:input "j"
            ed:sleep(100)
        end
        assert.equals(sent, requests())
    end)

    it("ignores a reply for a buffer that changed while it was in flight", function()
        start { symbols = { sym("stale", 12, R(0, 0, 4, 4)) }, reply_delays = { 300 } }
        -- Edit the buffer at the moment the first reply arrives, before breadcrumbs handles it.
        ed:lua [[
            local lsp, edited = require "micro.lsp", false
            local request = lsp.request
            lsp.request = function(key, win, method, params, handler, opts)
                return request(key, win, method, params, function(...)
                    if not edited then
                        edited = true
                        vim.api.nvim_buf_set_lines(0, 4, 5, false, { "edited" })
                    end
                    return handler(...)
                end, opts)
            end
        ]]
        enable()
        ed:sleep(700)
        assert.is_nil(bar():find("stale", 1, true))
    end)

    it("drops symbols when the server detaches", function()
        start { symbols = NESTED }
        enable()
        wait_bar "outer"
        ed:lua "vim.lsp.stop_client(vim.lsp.get_clients { bufnr = 0 }, true)"
        ed:wait "#vim.lsp.get_clients { bufnr = 0 } == 0"
        ed:wait(
            "vim.api.nvim_eval_statusline(vim.wo.winbar, { use_winbar = true }).str:find('outer', 1, true) == nil",
            2000
        )
    end)

    it("orders flat symbols outermost first, including equal starts", function()
        local uri = vim.uri_from_fname(root .. "/src/a.txt")
        local function info(name, kind, r)
            return { name = name, kind = kind, location = { uri = uri, range = r } }
        end
        start { symbols = { info("inner", 12, R(0, 0, 1, 13)), info("outer", 5, R(0, 0, 2, 3)) } }
        ed:lua [[vim.api.nvim_win_set_cursor(0, { 2, 2 })]]
        enable()
        wait_bar "inner"
        assert.truthy(bar():find "outer > .*inner")
    end)

    it("draws no bar on floating windows", function()
        enable()
        wait_bar "a.txt"
        local float = ed:lua [[
            return vim.api.nvim_open_win(0, true, { relative = "editor", row = 1, col = 1, width = 20, height = 3 })
        ]]
        ed:input "j"
        ed:sleep(200)
        assert.equals("", ed:lua("return vim.wo[...].winbar", float))
    end)

    it("forgets a buffer when it is unloaded", function()
        start { symbols = NESTED }
        enable()
        wait_bar "outer"
        ed:lua("vim.cmd.edit(...)", root .. "/src/b.txt")
        ed:lua("vim.cmd.bunload(vim.fn.bufnr(...))", root .. "/src/a.txt")
        ed:lua("vim.cmd.edit(...)", root .. "/src/a.txt")
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } == 0]] -- unloading detached the client
        start({ symbols = { sym("fresh", 12, R(0, 0, 2, 3)) } }, "sym2")
        wait_bar "fresh" -- nothing cached from before the unload
    end)
end)
