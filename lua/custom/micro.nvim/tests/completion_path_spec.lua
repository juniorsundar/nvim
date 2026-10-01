local Editor = require "tests.support.editor"

describe("micro.completion (path context)", function()
    local ed, dir

    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir .. "/my folder", "p")
        vim.fn.writefile({}, dir .. "/alpha.txt")
        vim.fn.writefile({}, dir .. "/.hidden")
        ed = Editor.new()
        ed:lua("vim.cmd.cd(...)", dir)
    end)
    after_each(function()
        ed:close()
        vim.fn.delete(dir, "rf")
    end)

    local function words_are(list)
        return ("vim.deep_equal((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end table.sort(w) return w end)(), %s)"):format(
            vim.inspect(list)
        )
    end

    local function log_count(log)
        return vim.fn.filereadable(log) == 1 and #vim.fn.readfile(log) or 0
    end

    it("offers only filesystem candidates after ./", function()
        ed:session { lines = { 'open("' }, row = 1, server = { delays = { 20 } } }
        ed:input "A./a"
        ed:wait(words_are { "alpha.txt" })
        assert.is_true(ed:state().visible)
    end)

    it("replaces only the final segment, keeping the prefix", function()
        ed:session { lines = { "BufThing", 'open("' }, server = { delays = { 20 } } }
        ed:input "A./my fo"
        ed:wait(words_are { "my folder/" })
        ed:input "<C-n><C-y>"
        ed:wait [[vim.api.nvim_get_current_line() == 'open("./my folder/']]
    end)

    it("keeps a multibyte prefix intact", function()
        ed:session { lines = { "BufThing", 'π("' }, server = { delays = { 20 } } }
        ed:input "A./my fo"
        ed:wait(words_are { "my folder/" })
        ed:input "<C-n><C-y>"
        ed:wait [[vim.api.nvim_get_current_line() == 'π("./my folder/']]
    end)

    it("never corrupts the prefix when a pending language request is overtaken", function()
        ed:session { lines = { "BufThing", "" }, server = { delays = { 600 } } }
        ed:input "Ao"
        ed:sleep(100) -- language request now in flight
        ed:input 'pen("./my fo'
        ed:wait(words_are { "my folder/" })
        ed:sleep(800) -- the late language reply arrives now
        ed:input "<C-n><C-y>"
        ed:wait [[vim.api.nvim_get_current_line() == 'open("./my folder/']]
    end)

    it("sends no language request while in a path context", function()
        local log = dir .. ".log"
        ed:session { lines = { 'open("./' }, row = 1, server = { delays = { 20 }, log = log } }
        ed:input "A" -- insert at end of the ./ path
        ed:input "my folder/" -- "/" is a server trigger character
        ed:wait [[vim.api.nvim_get_current_line() == 'open("./my folder/']]
        ed:lua [[vim.lsp.completion.get()]] -- manual native request
        ed:sleep(400)
        assert.equals(0, log_count(log))
        vim.fn.delete(log)
    end)

    it("restores language completion after leaving the path", function()
        local log = dir .. ".log"
        ed:session { lines = { "BufThing", 'open("./a' }, server = { delays = { 20 }, log = log } }
        ed:input "A<BS><BS><BS>"
        ed:input "<BS>x"
        ed:input "<Esc>"
        ed:lua [[vim.api.nvim_buf_set_lines(0, 1, 2, false, { "" })]]
        ed:input "ccTh"
        ed:wait [[vim.tbl_contains((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end return w end)(), "LspThing")]]
        assert.is_true(log_count(log) > 0)
        vim.fn.delete(log)
    end)

    it("re-routes when the cursor moves into a path without typing", function()
        ed:session { lines = { 'open("./a") Th', "" }, row = 1, server = { delays = { 20 } } }
        ed:input "A<Left><Left><Left><Left><Left>" -- just after "./a", no text change
        ed:wait [[vim.api.nvim_win_get_cursor(0)[2] == 9]]
        ed:input "<C-n>" -- manual native completion uses whatever route is active
        ed:wait(words_are { "alpha.txt" })
    end)
end)
