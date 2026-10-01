local Editor = require "tests.support.editor"

describe("micro.completion (language context)", function()
    local ed

    before_each(function()
        ed = Editor.new()
    end)
    after_each(function()
        ed:close()
    end)

    local function menu_has(word)
        return ("vim.tbl_contains((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end return w end)(), %q)"):format(
            word
        )
    end

    it("mixes LSP and current-buffer candidates", function()
        ed:session { server = { delays = { 20 } } }
        ed:input "iTh"
        ed:wait(menu_has "LspThing")
        local s = ed:state()
        assert.is_true(vim.tbl_contains(s.words, "BufThing"))
        assert.is_true(vim.tbl_contains(s.words, "LspThing"))
        assert.equals(-1, s.selected)
    end)

    it("shows buffer words when the server has no candidates", function()
        ed:session { server = { empty = true } }
        ed:input "iBu"
        ed:wait(menu_has "BufThing")
        assert.is_false(vim.tbl_contains(ed:state().words, "LspThing"))
    end)

    it("expands LSP snippets and applies additional edits on acceptance", function()
        ed:session { server = { snippet = true, import = true, delays = { 20 } } }
        ed:input "iLs"
        ed:wait(menu_has "LspCall")
        ed:input "<C-n><C-y>"
        ed:wait "vim.snippet.active()"
        local s = ed:state()
        assert.same({ "import LspThing", "BufThing", "LspCall(arg)" }, s.lines)
    end)

    it("applies resolve-time edits and shows resolved documentation", function()
        ed:session { server = { resolve_import = true, delays = { 20 } } }
        ed:input "iLs"
        ed:wait(menu_has "LspThing")
        ed:input "<C-n>"
        ed:wait [[(function()
            local b = vim.fn.complete_info({ "preview_bufnr" }).preview_bufnr
            return b and b > 0 and vim.api.nvim_buf_get_lines(b, 0, 1, false)[1] == "Probe documentation"
        end)()]]
        ed:input "<C-y>"
        ed:wait [[vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == 'import ResolvedThing']]
    end)

    it("does not reopen after <C-e> dismisses a request still in flight", function()
        ed:session { server = { delays = { 400 } } }
        ed:input "iLs"
        ed:sleep(120)
        ed:lua [[require("micro.completion").invalidate()]]
        ed:input "<C-e>"
        ed:sleep(700)
        assert.is_false(ed:state().visible)
    end)

    it("keeps an explicit selection when a late reply arrives", function()
        ed:session { server = { delays = { 20, 500 } } }
        ed:input "iBu"
        ed:wait(menu_has "BufThing")
        ed:input "<C-n>"
        ed:wait [[vim.fn.complete_info({'selected'}).selected == 0]]
        ed:sleep(800)
        assert.equals(0, ed:state().selected)
    end)

    it("accepts a reply while the user keeps typing the same word", function()
        ed:session { server = { delays = { 300 } } }
        ed:input "iL"
        ed:sleep(100)
        ed:input "s"
        ed:wait(menu_has "LspThing")
    end)

    it("accepts incomplete-result refreshes while typing", function()
        ed:session { server = { incomplete = true, delays = { 20 } } }
        ed:input "iLsp"
        ed:wait(menu_has "LspThing")
        ed:input "T"
        ed:wait(menu_has "LspThing")
        assert.is_true(ed:state().visible)
    end)

    it("drops replies after leaving insert mode", function()
        ed:session { server = { delays = { 400 } } }
        ed:input "iLs"
        ed:sleep(100)
        ed:input "<Esc>"
        ed:sleep(700)
        local s = ed:state()
        assert.is_false(s.visible)
        assert.equals("n", s.mode)
    end)

    it("drops replies after editing another line", function()
        ed:session { server = { delays = { 400 } } }
        ed:input "iLs"
        ed:sleep(100)
        ed:lua [[vim.api.nvim_buf_set_lines(0, 0, 1, false, { "Other" })]]
        ed:sleep(700)
        assert.is_false(ed:state().visible)
    end)

    it("drops replies after the document is renamed", function()
        ed:session { server = { delays = { 400 } } }
        ed:input "iLs"
        ed:sleep(100)
        ed:lua [[vim.cmd.file(vim.fn.tempname())]]
        ed:sleep(700)
        assert.is_false(ed:state().visible)
    end)

    it("combines two servers and recovers after dropping a slow reply", function()
        ed:session { server = { delays = { 20 } } }
        ed:lua(
            [[
            local server = ...
            vim.lsp.start {
                name = "other",
                cmd = require("micro.completion").wrap_cmd { "python3", server, vim.json.encode { label = "SlowThing", delays = { 600, 20 } } },
                root_dir = vim.fn.getcwd(),
            }
        ]],
            vim.fn.getcwd() .. "/tests/support/server.py"
        )
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } == 2]]
        ed:input "iTh"
        ed:wait(menu_has "BufThing")
        ed:input "<C-n>"
        ed:wait [[vim.fn.complete_info({'selected'}).selected == 0]]
        ed:sleep(900) -- the slow server replies now and must not wipe the selection
        assert.equals(0, ed:state().selected)
        ed:input "<C-e><Esc>An"
        ed:wait(menu_has "SlowThing")
        assert.is_true(vim.tbl_contains(ed:state().words, "LspThing"))
    end)

    it("still guards a double-decorated command after repeated setup", function()
        ed:lua [[
            local c = require "micro.completion"
            c.setup {}
            c.setup {}
        ]]
        ed:lua(
            [[
            local server = ...
            local c = require "micro.completion"
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "BufThing", "" })
            vim.api.nvim_win_set_cursor(0, { 2, 0 })
            local cmd = c.wrap_cmd(c.wrap_cmd { "python3", server, vim.json.encode { delays = { 20, 500 } } })
            vim.lsp.start { name = "twice", cmd = cmd, root_dir = vim.fn.getcwd() }
        ]],
            vim.fn.getcwd() .. "/tests/support/server.py"
        )
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        ed:wait [[vim.b.micro_completion_route ~= nil]]
        ed:input "iTh"
        ed:wait(menu_has "LspThing") -- fresh reply is delivered
        ed:input "<C-n>"
        ed:wait [[vim.fn.complete_info({'selected'}).selected >= 0]]
        ed:sleep(800) -- a stale reply must not reset the selection
        assert.is_true(ed:state().selected >= 0)
    end)

    it("leaves the server usable when it never answers", function()
        ed:session { server = { never_reply = true } }
        ed:input "iBu"
        ed:sleep(300)
        ed:input "<Esc>"
        ed:wait [[vim.api.nvim_get_mode().mode == "n"]]
        assert.is_false(ed:state().visible)
    end)
end)
