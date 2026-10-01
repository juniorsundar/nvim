local Editor = require "tests.support.editor"

describe("micro.completion (exclusions)", function()
    local ed, log

    before_each(function()
        log = vim.fn.tempname()
        ed = Editor.new()
    end)
    after_each(function()
        ed:close()
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

    local function assert_silent(keys)
        ed:input(keys)
        ed:sleep(600)
        assert.is_false(ed:state().visible)
        assert.equals(0, requests())
    end

    -- A refer-shaped prompt keeps its own buffer-local Tab mapping.
    local function map_tab()
        ed:lua [[vim.keymap.set("i", "<Tab>", "<C-r>=''<CR>TAB", { buffer = true })]]
    end

    for _, shape in ipairs {
        { "refer_input", "nofile" },
        { "refer_results", "nofile" },
        { "refer_input", "" }, -- excluded by filetype alone
    } do
        it(("excludes a %s buffer (buftype %q) and leaves its Tab mapping alone"):format(shape[1], shape[2]), function()
            ed:session { filetype = shape[1], buftype = shape[2], server = { delays = { 20 }, log = log } }
            map_tab()
            assert_silent "iBu"
            ed:input "<Tab>"
            ed:wait [[vim.api.nvim_get_current_line():find("TAB", 1, true) ~= nil]]
            assert.is_false(ed:state().visible)
        end)
    end

    it("excludes any non-file buffer", function()
        ed:session { buftype = "nofile", server = { delays = { 20 }, log = log } }
        assert_silent "iBu"
    end)

    it("drops a reply already in flight when vim.b.completion becomes false", function()
        ed:session { server = { delays = { 400 }, log = log } }
        ed:input "iTh" -- matches LspThing, so the reply would show if delivered
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log))
        ed:lua [[vim.b.completion = false]]
        ed:sleep(800)
        assert.is_false(vim.tbl_contains(ed:state().words, "LspThing"))
    end)

    it("refuses a new request when vim.b.completion is false, even before routing notices", function()
        ed:session { server = { delays = { 20 }, log = log } }
        ed:input "iTh"
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log))
        ed:input "<C-e>"
        local before = requests()
        -- One call: no event can re-route between setting the flag and requesting.
        ed:lua [[
            vim.b.completion = false
            vim.lsp.completion.get()
        ]]
        ed:sleep(500)
        assert.equals(before, requests())
    end)

    it("re-enables completion when vim.b.completion is set back", function()
        ed:session { server = { delays = { 20 }, log = log } }
        ed:lua [[vim.b.completion = false]]
        assert_silent "iBu"
        ed:lua [[vim.b.completion = nil]]
        ed:input "<Esc>cc"
        ed:input "Th"
        ed:wait(menu_has "LspThing")
    end)

    it("does not affect other buffers", function()
        ed:session { server = { delays = { 20 }, log = log } }
        ed:lua [[vim.b.completion = false]]
        ed:lua [[vim.cmd.enew(); vim.bo.filetype = "other"]]
        ed:lua [[vim.api.nvim_buf_set_lines(0, 0, -1, false, { "BufThing", "" }); vim.api.nvim_win_set_cursor(0, { 2, 0 })]]
        ed:input "iBu"
        ed:wait(menu_has "BufThing")
    end)
end)
