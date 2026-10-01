local Editor = require "tests.support.editor"

describe("micro.completion (automatic triggering)", function()
    local ed, dir, log
    -- 0.12.5 documents 'autocompletedelay' but ignores it (verified: the menu opens
    -- immediately with the option set to 600); nightly honours it.
    local honours_delay = vim.fn.has "nvim-0.13" == 1

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

    it("does not open for one word character but does for two", function()
        ed:session { server = { delays = { 20 }, log = log } }
        ed:input "iB"
        ed:sleep(500)
        assert.is_false(ed:state().visible)
        assert.equals(0, requests())
        ed:input "u"
        ed:wait(menu_has "BufThing")
    end)

    it("honours a configured minimum word length", function()
        ed:session { micro = { min_word_length = 3 }, server = { delays = { 20 }, log = log } }
        ed:input "iBu"
        ed:sleep(500)
        assert.is_false(ed:state().visible)
        ed:input "f"
        ed:wait(menu_has "BufThing")
    end)

    it("honours a configured debounce", function()
        if not honours_delay then
            return pending "needs native 'autocompletedelay' (nightly only)"
        end
        ed:session { micro = { debounce = 600 }, server = { delays = { 20 }, log = log } }
        ed:input "iBu"
        ed:sleep(250)
        assert.is_false(ed:state().visible)
        ed:wait(menu_has "BufThing", 2000)
    end)

    it("does not flood the server while typing within the debounce", function()
        if not honours_delay then
            return pending "needs native 'autocompletedelay' (nightly only)"
        end
        -- No matches, so no popup ever suppresses new attempts: each keystroke would
        -- otherwise start a request.
        ed:session { micro = { debounce = 400 }, server = { empty = true, delays = { 20 }, log = log } }
        ed:input "i"
        for _, key in ipairs { "z", "q", "w", "e", "r", "t" } do
            ed:input(key)
            ed:sleep(100)
        end
        ed:sleep(900)
        local sent = requests()
        assert.is_true(sent >= 1, "settled request expected, got " .. sent)
        assert.is_true(sent <= 2, "requests: " .. sent)
    end)

    it("opens on a server trigger character without waiting for the threshold or debounce", function()
        ed:session { micro = { debounce = 5000 }, server = { delays = { 20 }, log = log } }
        ed:input "i."
        ed:wait(menu_has "LspThing", 1500)
    end)

    it("re-arms after backspacing below the threshold", function()
        ed:session { server = { delays = { 20 }, log = log } }
        ed:input "iBu"
        ed:wait(menu_has "BufThing")
        ed:input "<C-e><BS><BS>B"
        ed:sleep(500)
        assert.is_false(ed:state().visible)
        ed:input "u"
        ed:wait(menu_has "BufThing")
    end)

    it("opens path completion on a path separator regardless of word length", function()
        ed:session { lines = { 'open("' }, row = 1, micro = { debounce = 5000 }, server = { delays = { 20 }, log = log } }
        ed:input "A./"
        ed:wait(menu_has "alpha.txt", 1500)
        assert.equals(0, requests())
    end)

    it("does not leak the immediate path delay after leaving insert mode", function()
        ed:session { lines = { 'open("' }, row = 1, micro = { debounce = 123 }, server = { delays = { 20 } } }
        ed:input "A./"
        ed:wait(menu_has "alpha.txt")
        ed:input "<C-e><Esc>"
        ed:wait [[vim.api.nvim_get_mode().mode == "n"]]
        assert.equals(123, ed:lua "return vim.o.autocompletedelay")
    end)
end)
