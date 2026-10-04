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
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log))
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

    describe("candidate ranking", function()
        local VARIABLE, FUNCTION = 6, 3

        -- The server ranks functions ahead of variables, as lua-language-server does.
        local function rank(typed, lines)
            ed:session {
                lines = lines or { "", "" },
                server = {
                    delays = { 20 },
                    items = {
                        { label = "load_user_profile_settings", kind = FUNCTION, sortText = "0001" },
                        { label = "load_user_profile", kind = VARIABLE, sortText = "0002" },
                        { label = "load_user_prefs", kind = VARIABLE, sortText = "0003" },
                    },
                },
            }
            ed:input("i" .. typed)
            ed:wait(has "load_user_profile")
            ed:sleep(300)
            return menu()
        end

        it("ranks an exact match first, over the server's order", function()
            local words = rank "load_user_profile"
            assert.equals("load_user_profile:Variable", words[1])
            assert.equals("load_user_profile_settings:Function", words[2])
        end)

        it("ranks a closer match first for a typed prefix", function()
            -- Shorter leftovers win: the variable beats the function the server listed first.
            assert.same({
                "load_user_prefs:Variable",
                "load_user_profile:Variable",
                "load_user_profile_settings:Function",
            }, rank "load_user_p")
        end)

        it("keeps the server's order between equally good matches", function()
            ed:session {
                server = {
                    delays = { 20 },
                    items = {
                        { label = "tie_bravo", sortText = "1" },
                        { label = "tie_alpha", sortText = "2" },
                    },
                },
            }
            ed:input "itie"
            ed:wait(has "tie_alpha")
            ed:sleep(300)
            assert.same({ "tie_bravo:Function", "tie_alpha:Function" }, menu())
        end)

        it("falls back to the label when the server sends no sortText", function()
            ed:session {
                server = { delays = { 20 }, items = { { label = "tie_bravo" }, { label = "tie_alpha" } } },
            }
            ed:input "itie"
            ed:wait(has "tie_alpha")
            ed:sleep(300)
            assert.same({ "tie_alpha:Function", "tie_bravo:Function" }, menu())
        end)

        it("keeps LSP candidates ahead of an exact buffer word, then ranks buffer words by match", function()
            local words = rank("load_user", { "load_userXXXXXXXX load_user", "" })
            -- Buffer words have an empty kind, so they end in ":".
            assert.same(
                { false, false, false, true, true },
                vim.tbl_map(function(w)
                    return w:sub(-1) == ":"
                end, words)
            )
            assert.same({ "load_user:", "load_userXXXXXXXX:" }, { words[4], words[5] })
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
