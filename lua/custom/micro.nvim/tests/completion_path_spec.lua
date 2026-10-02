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
        ed:input "Aop"
        ed:sleep(250) -- language request now in flight
        ed:input 'en("./my fo'
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

    describe("path rules", function()
        local function type_path(line, keys)
            ed:session { lines = { line }, row = 1, server = { delays = { 20 } } }
            ed:input("A" .. keys)
        end

        before_each(function()
            vim.fn.mkdir(dir .. "/src/inner", "p")
            vim.fn.mkdir(dir .. "/other", "p")
            vim.fn.writefile({}, dir .. "/src/index.lua")
            vim.fn.writefile({}, dir .. "/src/inner/deep.txt")
            vim.fn.writefile({}, dir .. "/zzz.txt")
        end)

        it("treats src/-style relative segments as paths and completes nested ones", function()
            type_path('open("', "src/")
            ed:input "<C-n>"
            ed:wait(words_are { "index.lua", "inner/" })
            ed:input "<C-e>inner/"
            ed:input "<C-n>"
            ed:wait(words_are { "deep.txt" })
        end)

        it("completes ../ from the working directory's parent", function()
            ed:lua("vim.cmd.cd(...)", dir .. "/src")
            type_path('open("', "../al")
            ed:wait(words_are { "alpha.txt" })
        end)

        it("completes absolute paths, quoted and unquoted", function()
            type_path('open("', dir .. "/al")
            ed:wait(words_are { "alpha.txt" })
            ed:input "<C-e><Esc>cc"
            ed:input("x = " .. dir .. "/zz")
            ed:wait(words_are { "zzz.txt" })
        end)

        it("completes ~/ against the home directory", function()
            ed:lua("vim.env.HOME = ...", dir .. "/src")
            type_path('open("', "~/in")
            ed:wait(words_are { "index.lua", "inner/" })
        end)

        it("marks directories with a trailing slash and removes unrelated entries", function()
            type_path('open("', "./ot")
            ed:wait(words_are { "other/" })
        end)

        it("lists dotfiles only when the segment starts with a dot", function()
            type_path('open("', "./")
            ed:input "<C-n>"
            ed:wait [[vim.fn.pumvisible() == 1]]
            assert.is_false(vim.tbl_contains(ed:state().words, ".hidden"))
            ed:input ".h"
            ed:wait(words_are { ".hidden" })
        end)

        it("completes names with spaces inside quoted paths", function()
            type_path('cp("', "./my fo")
            ed:wait(words_are { "my folder/" })
        end)

        it("does not treat environment variables or globs as paths", function()
            type_path("x = ", "$HOME/Th")
            ed:wait [[vim.tbl_contains(vim.fn.complete_info({'matches'}).matches[1] and (function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches) do w[#w+1] = i.word end return w end)() or {}, "LspThing")]]
            ed:input "<C-e><Esc>cc"
            ed:input "y = */Th"
            ed:wait [[vim.tbl_contains((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end return w end)(), "LspThing")]]
        end)

        it("does not treat quoted environment variables or globs as paths", function()
            type_path('open("', "$HOME/Th")
            ed:wait [[vim.tbl_contains((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end return w end)(), "LspThing")]]
            ed:input "<C-e><Esc>cc"
            ed:input 'open("*/Th'
            ed:wait [[vim.tbl_contains((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end return w end)(), "LspThing")]]
        end)

        it("does not treat numeric division as a path", function()
            type_path("x = 1.5", "/Th")
            ed:wait [[vim.tbl_contains((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end return w end)(), "LspThing")]]
        end)

        it("keeps division in code as language completion", function()
            type_path("local r = ", "total/Th")
            ed:wait [[vim.b.micro_completion_route == "language"]]
            ed:wait [[vim.tbl_contains((function() local w = {} for _, i in ipairs(vim.fn.complete_info({'matches'}).matches or {}) do w[#w+1] = i.word end return w end)(), "LspThing")]]
        end)

        it("treats an unquoted word/ as a path when that directory exists", function()
            type_path("ls ", "src/")
            ed:input "<C-n>"
            ed:wait(words_are { "index.lua", "inner/" })
            ed:input "<C-e>inner/"
            ed:input "<C-n>"
            ed:wait(words_are { "deep.txt" }) -- nested segments resolve from the first one
        end)

        it("checks an unquoted word/ against the window cwd, not the buffer directory", function()
            ed:session { lines = { "ls " }, row = 1, server = { delays = { 20 } } }
            ed:lua("vim.api.nvim_buf_set_name(0, ...)", dir .. "/other/x.sh") -- other/ has no src/
            ed:input "Asrc/"
            ed:wait [[vim.b.micro_completion_route == "path"]]
        end)

        it("resolves relative paths from the window cwd, not the buffer directory", function()
            local other = vim.fn.tempname()
            vim.fn.mkdir(other, "p")
            vim.fn.writefile({}, other .. "/beta.txt")
            ed:session { lines = { 'open("' }, row = 1, server = { delays = { 20 } } }
            ed:lua("vim.api.nvim_buf_set_name(0, ...)", dir .. "/src/x.lua")
            ed:lua("vim.cmd.lcd(...)", other)
            ed:input "A./b"
            ed:wait(words_are { "beta.txt" })
            ed:input "<C-e><BS><BS><BS>"
            ed:lua("vim.cmd.tcd(...)", dir .. "/other")
            ed:input "../zz"
            ed:wait(words_are { "zzz.txt" })
            vim.fn.delete(other, "rf")
        end)

        it("shows nothing for a missing directory without erroring", function()
            type_path('open("', "./nope/")
            ed:input "<C-n>"
            ed:sleep(300)
            assert.is_false(ed:state().visible)
            assert.equals("", ed:lua [[return vim.v.errmsg]])
        end)
    end)
end)
