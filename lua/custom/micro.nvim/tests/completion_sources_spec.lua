local Editor = require "tests.support.editor"

describe("micro.completion (source toggles)", function()
    local ed, log, dir

    before_each(function()
        log = vim.fn.tempname()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir, "p")
        vim.fn.writefile({}, dir .. "/alpha.txt")
        ed = Editor.new()
        ed:lua("vim.cmd.cd(...)", dir)
    end)
    after_each(function()
        ed:close()
        vim.fn.delete(log)
        vim.fn.delete(dir, "rf")
    end)

    local function requests()
        return vim.fn.filereadable(log) == 1 and #vim.fn.readfile(log) or 0
    end

    local function has(word)
        return ("vim.tbl_contains((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end return w end)(), %q)"):format(
            word
        )
    end

    it("leaves out current-buffer words when buffer is off", function()
        ed:session { micro = { sources = { buffer = false } }, server = { delays = { 20 } } }
        ed:input "iTh"
        ed:wait(has "LspThing")
        assert.is_false(vim.tbl_contains(ed:state().words, "BufThing"))
    end)

    it("sends no LSP request and shows only buffer words when lsp is off", function()
        ed:session { micro = { sources = { lsp = false } }, server = { delays = { 20 }, log = log } }
        ed:input "iTh"
        ed:wait(has "BufThing")
        ed:sleep(400)
        assert.is_false(vim.tbl_contains(ed:state().words, "LspThing"))
        -- manual omni-completion goes through 'omnifunc', which bypasses native autocompletion
        ed:input "<Esc>ccTh<C-x><C-o>"
        ed:sleep(400)
        assert.equals(0, requests())
    end)

    it("falls back to language completion in path-shaped text when path is off", function()
        ed:session {
            lines = { 'open("' },
            row = 1,
            micro = { sources = { path = false } },
            server = { delays = { 20 }, log = log },
        }
        ed:input "A./"
        ed:wait [[vim.b.micro_completion_route == "language"]]
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log)) -- the "/" trigger reaches the LSP
        ed:sleep(300)
        assert.is_false(vim.tbl_contains(ed:state().words, "alpha.txt"))
    end)

    it("keeps every source by default", function()
        ed:session { server = { delays = { 20 } } }
        ed:input "iTh"
        ed:wait(has "LspThing")
        assert.is_true(vim.tbl_contains(ed:state().words, "BufThing"))
    end)

    -- Words as "word:kind" in menu order; buffer words have an empty kind.
    local function menu()
        return ed:lua [[
            return vim.tbl_map(function(i) return i.word .. ":" .. i.kind end, vim.fn.complete_info({ "matches" }).matches or {})
        ]]
    end

    describe("prefer_lsp", function()
        -- The buffer holds the same word the server suggests, plus an unrelated buffer word.
        local function same_word(micro, delay)
            ed:session {
                lines = { "BufThing BufOther", "" },
                micro = micro,
                server = { label = "BufThing", delays = { delay } },
            }
            ed:input "iBu"
            ed:wait(has "BufOther")
            ed:sleep(800) -- let the LSP reply land whether it is slow or fast
        end

        for _, delay in ipairs { 20, 500 } do
            it(("shows only the LSP copy of a shared word and lists it first (reply %d ms)"):format(delay), function()
                same_word({}, delay)
                assert.same({ "BufThing:Function", "BufOther:" }, menu())
            end)
        end

        it("keeps both copies when prefer_lsp is off", function()
            same_word({ prefer_lsp = false }, 20)
            local words = menu()
            assert.equals(3, #words)
            assert.is_true(vim.tbl_contains(words, "BufThing:"))
            assert.is_true(vim.tbl_contains(words, "BufThing:Function"))
        end)

        it("lists LSP items ahead of buffer words that do not repeat", function()
            ed:session {
                lines = { "BuFirst BuSecond", "" },
                server = { label = "BuLsp", delays = { 20 } },
            }
            ed:input "iBu"
            ed:wait(has "BuLsp")
            ed:sleep(300)
            assert.equals("BuLsp:Function", menu()[1])
        end)
    end)

    describe("skip_kinds", function()
        local TEXT = 1 -- LSP CompletionItemKind.Text

        it("drops LSP items of a skipped kind and keeps buffer words", function()
            ed:session { micro = { skip_kinds = { "Text" } }, server = { kind = TEXT, delays = { 20 } } }
            ed:input "iTh"
            ed:wait(has "BufThing")
            ed:sleep(400)
            assert.is_false(vim.tbl_contains(ed:state().words, "LspThing"))
        end)

        it("keeps LSP items of other kinds", function()
            ed:session { micro = { skip_kinds = { "Text" } }, server = { delays = { 20 } } }
            ed:input "iTh"
            ed:wait(has "LspThing")
        end)

        it("keeps Text items when nothing is skipped", function()
            ed:session { server = { kind = TEXT, delays = { 20 } } }
            ed:input "iTh"
            ed:wait(has "LspThing")
        end)

        it("ignores a kind name that does not exist", function()
            ed:session { micro = { skip_kinds = { "Nope" } }, server = { delays = { 20 } } }
            ed:input "iTh"
            ed:wait(has "LspThing")
        end)
    end)
end)
