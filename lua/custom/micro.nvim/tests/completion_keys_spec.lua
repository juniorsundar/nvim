local Editor = require "tests.support.editor"

describe("micro.completion_keys", function()
    local ed, dir, log

    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        vim.fn.writefile({}, dir .. "/alpha.txt")
        log = dir .. ".log"
        ed = Editor.new()
        ed:lua("vim.cmd.cd(...)", dir)
    end)
    after_each(function()
        ed:close()
        vim.fn.delete(dir, "rf")
        vim.fn.delete(log)
    end)

    local function requests()
        return vim.fn.filereadable(log) == 1 and #vim.fn.readfile(log) or 0
    end

    local function menu_has(word)
        return ("vim.tbl_contains((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end return w end)(), %q)"):format(
            word
        )
    end

    describe("<C-Space>", function()
        it("opens a language-context menu without reaching the word threshold", function()
            ed:session { server = { delays = { 20 }, log = log } }
            ed:input "iT"
            ed:sleep(400)
            assert.is_false(ed:state().visible)
            ed:input "<C-Space>"
            ed:wait(menu_has "BufThing")
            ed:wait(menu_has "LspThing")
            assert.equals(-1, ed:state().selected)
        end)

        it("opens exclusive path completion inside a path", function()
            ed:session { lines = { 'open("./' }, row = 1, server = { delays = { 20 }, log = log } }
            ed:input "A<C-e><C-Space>"
            ed:wait(menu_has "alpha.txt")
            assert.is_false(vim.tbl_contains(ed:state().words, "LspThing"))
            assert.equals(0, requests())
        end)

        it("routes before opening, so a just-excluded buffer gets nothing", function()
            ed:session { server = { delays = { 20 }, log = log } }
            ed:input "i"
            -- One call: no event can re-route between flipping the flag and the key's expression.
            local out = ed:lua [[
                vim.b.completion = false
                return vim.fn.maparg("<C-Space>", "i", false, true).callback()
            ]]
            assert.equals("", out)
        end)

        it("does nothing in an excluded buffer", function()
            ed:session { buftype = "nofile", server = { delays = { 20 }, log = log } }
            ed:input "iB<C-Space>"
            ed:sleep(500)
            assert.is_false(ed:state().visible)
            assert.equals(0, requests())
        end)
    end)

    describe("<CR>", function()
        it("inserts a newline when nothing is selected", function()
            ed:session { server = { delays = { 20 } } }
            ed:input "iBu"
            ed:wait(menu_has "BufThing")
            ed:input "<CR>"
            ed:wait [[#vim.api.nvim_buf_get_lines(0, 0, -1, false) == 3]]
            assert.same({ "BufThing", "Bu", "" }, ed:state().lines)
        end)

        it("accepts an explicitly selected candidate", function()
            ed:session { server = { delays = { 20 } } }
            ed:input "iBu"
            ed:wait(menu_has "BufThing")
            ed:input "<C-n><CR>"
            ed:wait [[vim.api.nvim_get_current_line() == "BufThing"]]
            assert.equals(2, #ed:state().lines)
        end)
    end)

    describe("<Tab> / <S-Tab>", function()
        it("moves through an open menu and back", function()
            ed:session { server = { delays = { 20 } } }
            ed:input "iTh"
            ed:wait(menu_has "LspThing")
            ed:input "<Tab>"
            ed:wait [[vim.fn.complete_info({'selected'}).selected == 0]]
            ed:input "<S-Tab>"
            ed:wait [[vim.fn.complete_info({'selected'}).selected == -1]]
        end)

        it("keeps normal Tab behaviour with no menu and no snippet", function()
            ed:session { server = { empty = true } }
            ed:input "i<Tab>"
            ed:wait [[vim.api.nvim_get_current_line():find("\t", 1, true) ~= nil]]
        end)

        it("jumps between snippet placeholders when no menu is open", function()
            ed:session { server = { snippet = true, delays = { 20 } } }
            ed:input "iLs"
            ed:wait(menu_has "LspCall")
            ed:input "<C-n><C-y>"
            ed:wait "vim.snippet.active()"
            ed:input "<Tab>" -- final stop ($0): snippet ends
            ed:wait "not vim.snippet.active()"
            assert.equals("LspCall(arg)", ed:state().lines[2])
        end)

        it("jumps placeholders in select mode too", function()
            ed:session { server = { snippet = true, delays = { 20 } } }
            ed:input "iLs"
            ed:wait(menu_has "LspCall")
            ed:input "<C-n><C-y>"
            ed:wait [[vim.snippet.active() and vim.api.nvim_get_mode().mode == "s"]]
            ed:input "<Tab>"
            ed:wait "not vim.snippet.active()"
        end)

        it("keeps the snippet active while the menu is navigated inside a placeholder", function()
            ed:session { server = { snippet = true, delays = { 20 } } }
            ed:input "iLs"
            ed:wait(menu_has "LspCall")
            ed:input "<C-n><C-y>"
            ed:wait "vim.snippet.active()"
            ed:input "Th" -- type inside the placeholder; a menu opens
            ed:wait [[vim.fn.pumvisible() == 1]]
            ed:input "<Tab>"
            ed:wait [[vim.fn.complete_info({'selected'}).selected >= 0]]
            assert.is_true(ed:state().snippet)
        end)
    end)

    describe("<C-e>", function()
        it("cancels an open menu", function()
            ed:session { server = { delays = { 20 } } }
            ed:input "iBu"
            ed:wait(menu_has "BufThing")
            ed:input "<C-e>"
            ed:wait [[vim.fn.pumvisible() == 0]]
        end)

        it("cancels a request still in flight with no menu, so it never reopens", function()
            -- A trigger character requests with no completion mode active, so native <C-e> fires no
            -- CompleteDone and only the key's own invalidate blocks the late reply.
            ed:session { lines = { "x", "" }, server = { delays = { 400 }, log = log } }
            ed:input "i."
            ed:wait(("vim.fn.filereadable(%q) == 1"):format(log))
            assert.is_false(ed:state().visible)
            ed:input "<C-e>"
            ed:sleep(800)
            assert.is_false(ed:state().visible)
        end)
    end)

    describe("<C-b> / <C-f>", function()
        -- The documentation window is recreated when resolved docs arrive, so poll its topline
        -- rather than holding a window id.
        local TOPLINE = [[(function()
            local w = vim.fn.complete_info({ "selected" }).preview_winid
            if not w or not vim.api.nvim_win_is_valid(w) then return nil end
            return vim.api.nvim_win_call(w, function() return vim.fn.line("w0") end)
        end)()]]

        it("scrolls the documentation popup while it is open", function()
            ed:session { server = { delays = { 20 } } }
            ed:input "iLs"
            ed:wait(menu_has "LspThing")
            ed:input "<C-n>"
            ed:wait("(" .. TOPLINE .. ") == 1")
            ed:input "<C-f>"
            ed:wait("(" .. TOPLINE .. ") ~= nil and (" .. TOPLINE .. ") > 1")
            local state = ed:state()
            assert.equals(0, state.selected)
            assert.same({ "BufThing", "LspThing" }, vim.list_slice(state.lines, 1, 2))
        end)

        it("returns the native key when no documentation popup is showing", function()
            ed:session { server = { empty = true } }
            ed:input "iBu"
            ed:wait(menu_has "BufThing")
            -- Evaluate the mapping's expression with the menu open but no docs window.
            local out = ed:lua [[
                local m = vim.fn.maparg("<C-f>", "i", false, true)
                return vim.api.nvim_replace_termcodes(m.callback(), true, false, true)
            ]]
            assert.equals(vim.keycode "<C-f>", out)
        end)
    end)

    it("leaves a refer-shaped buffer's own Tab mapping alone", function()
        ed:session { filetype = "refer_input", buftype = "nofile", server = { delays = { 20 } } }
        ed:lua [[vim.keymap.set("i", "<Tab>", "<C-r>=''<CR>TAB", { buffer = true })]]
        ed:input "iBu<Tab>"
        ed:wait [[vim.api.nvim_get_current_line():find("TAB", 1, true) ~= nil]]
    end)
end)
