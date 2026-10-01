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
end)
