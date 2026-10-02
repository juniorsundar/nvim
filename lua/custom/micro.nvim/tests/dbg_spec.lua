local Editor = require "tests.support.editor"
local function R(l1, c1, l2, c2)
    return { start = { line = l1, character = c1 }, ["end"] = { line = l2, character = c2 } }
end
local function sym(name, kind, r, children)
    return { name = name, kind = kind, range = r, selectionRange = r, children = children }
end
describe("breadcrumbs probe", function()
    local ed, root
    before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(root, "p")
        vim.fn.writefile({ "function outer()", "  local x = 1", "end", "", "tail" }, root .. "/a.txt")
        vim.fn.writefile({ "other" }, root .. "/b.txt")
        ed = Editor.new()
        ed:lua("vim.cmd.cd(...); vim.notify = function() end", root)
    end)
    after_each(function()
        ed:close()
        vim.fn.delete(root, "rf")
    end)

    it("probes", function()
        local syms = { sym("outer", 12, R(0, 0, 2, 3), { sym("x", 13, R(1, 2, 1, 13)) }) }
        ed:lua("vim.cmd.edit(...)", root .. "/a.txt")
        ed:server({ symbols = syms, log = root .. "/log" }, "sym")
        ed:lua [[vim.o.updatetime = 50; vim.api.nvim_win_set_cursor(0, { 2, 8 })]]
        ed:lua [[require("micro.breadcrumbs").enable()]]
        ed:wait("vim.wo.winbar:find('outer') ~= nil", 5000)
        print("1 winbar:", ed:lua "return vim.wo.winbar")
        print("1 global vs local:", ed:lua "return vim.go.winbar == vim.wo.winbar")

        -- split: does the other window inherit/lose the bar?
        ed:lua([[vim.cmd "vsplit"; vim.cmd.edit(...)]], root .. "/b.txt")
        ed:sleep(600)
        print(
            "2 after split, wins:",
            vim.inspect(
                ed:lua [[return vim.tbl_map(function(w) return { vim.fn.bufname(vim.api.nvim_win_get_buf(w)), vim.wo[w].winbar } end, vim.api.nvim_list_wins())]]
            )
        )

        -- cursor outside any symbol (line 5), CursorHold
        ed:lua [[vim.cmd "wincmd p"; vim.api.nvim_win_set_cursor(0, { 5, 0 })]]
        ed:lua [[vim.api.nvim_exec_autocmds("CursorHold", {})]]
        ed:sleep(700)
        print("3 outside symbol:", ed:lua "return vim.wo.winbar")

        -- no CursorHold: move cursor via feedkeys only (real user), does the bar update?
        ed:input "gg"
        ed:sleep(300)
        print("4 moved, before CursorHold fires naturally:", ed:lua "return vim.wo.winbar")
        ed:sleep(700)
        print("4b after updatetime:", ed:lua "return vim.wo.winbar")

        -- request count over 2s of idle with CursorHold only firing once per hold
        print("5 requests logged:", #vim.fn.readfile(root .. "/log"))

        -- help buffer (non-file uri)
        ed:lua [[vim.cmd "help help"]]
        ed:sleep(400)
        print("6 help window winbar:", ed:lua "return vim.wo.winbar", "global:", ed:lua "return vim.go.winbar")
        ed:lua [[vim.cmd "close"]]

        -- server returns SymbolInformation[] (flat, location instead of range)
        print("7 errmsg so far:", ed:lua "return vim.v.errmsg")
    end)

    it("flat SymbolInformation reply", function()
        ed:lua("vim.cmd.edit(...)", root .. "/a.txt")
        local uri = vim.uri_from_fname(root .. "/a.txt")
        ed:server(
            { symbols = { { name = "outer", kind = 12, location = { uri = uri, range = R(0, 0, 2, 3) } } } },
            "sym"
        )
        ed:lua [[vim.api.nvim_win_set_cursor(0, { 2, 2 })]]
        local ok, err = pcall(function()
            ed:lua [[require("micro.breadcrumbs").enable()]]
        end)
        ed:sleep(800)
        print(
            "8 SymbolInformation:",
            ok,
            err,
            "winbar:",
            ed:lua "return vim.wo.winbar",
            "errmsg:",
            ed:lua "return vim.v.errmsg"
        )
        print("8 messages:", (ed:lua [[return vim.api.nvim_exec2("messages", { output = true }).output]]):sub(-300))
    end)

    it("end-of-range cursor", function()
        ed:lua("vim.cmd.edit(...)", root .. "/a.txt")
        -- outer ends at (2,3) exclusive per LSP; cursor at col 3 on line 3 is just past 'end'
        ed:server({ symbols = { sym("outer", 12, R(0, 0, 2, 3)), sym("next", 12, R(2, 3, 4, 4)) } }, "sym")
        ed:lua [[vim.api.nvim_win_set_cursor(0, { 3, 3 })]]
        ed:lua [[require("micro.breadcrumbs").enable()]]
        ed:sleep(800)
        print("9 cursor at shared boundary picks:", ed:lua "return vim.wo.winbar")
    end)
end)
