local Editor = require "tests.support.editor"

describe("micro.lsp", function()
    local ed, log

    before_each(function()
        log = vim.fn.tempname()
        ed = Editor.new()
        ed:lua [[
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ééé xy" })
            vim.api.nvim_win_set_cursor(0, { 1, 7 }) -- byte 7 = "x", UTF-16 character 4
            _G.got = {}
            function _G.hover(opts)
                require("micro.lsp").request("k", 0, "textDocument/hover", function(client)
                    return vim.lsp.util.make_position_params(0, client.offset_encoding)
                end, function(_, result)
                    if result then
                        table.insert(_G.got, result.contents.value)
                        return true
                    end
                end, opts)
            end
        ]]
    end)
    after_each(function()
        ed:close()
        vim.fn.delete(log)
    end)

    local function requests()
        return vim.fn.filereadable(log) == 1 and #vim.fn.readfile(log) or 0
    end
    local function got()
        return ed:lua "return _G.got"
    end

    it("sends nothing and stays silent without a capable client", function()
        ed:server({}, "plain")
        ed:lua "_G.hover()"
        ed:sleep(200)
        assert.same({}, got())
        assert.equals("", ed:lua "return vim.trim(vim.fn.execute('messages'))")
    end)

    it("skips a client without the capability and uses the next one", function()
        ed:server({}, "plain")
        ed:server({ hover = "B" }, "b")
        ed:lua "_G.hover()"
        ed:wait "#_G.got == 1"
        assert.same({ "B @0:4" }, got())
    end)

    it("falls back to a later client when the first reply is empty", function()
        ed:server({ hover = "" }, "empty")
        ed:server({ hover = "B", reply_delays = { 100 } }, "b")
        ed:lua "_G.hover()"
        ed:wait "#_G.got == 1"
        ed:sleep(200)
        assert.same({ "B @0:4" }, got())
    end)

    it("builds positions in each client's negotiated encoding", function()
        ed:server({ hover = "U8", encoding = "utf-8" }, "u8")
        ed:lua "_G.hover()"
        ed:wait "#_G.got == 1"
        assert.same({ "U8 @0:7" }, got())
    end)

    it("drops a reply that arrives after cancel", function()
        ed:server({ hover = "B", reply_delays = { 200 }, log = log }, "b")
        ed:lua "_G.hover(); require('micro.lsp').cancel('k')"
        ed:sleep(400)
        assert.equals(1, requests())
        assert.same({}, got())
    end)

    it("only delivers the latest request for a key", function()
        ed:server({ hover = "B", reply_delays = { 200, 0 }, log = log }, "b")
        ed:lua "_G.hover()"
        ed:wait "true"
        ed:lua "vim.api.nvim_win_set_cursor(0, { 1, 0 }); _G.hover()"
        ed:sleep(400)
        assert.equals(2, requests())
        assert.same({ "B @0:0" }, got())
    end)

    it("debounces bursts into one request", function()
        ed:server({ hover = "B", log = log }, "b")
        ed:lua "for _ = 1, 5 do _G.hover { debounce = 50 } end"
        ed:wait "#_G.got == 1"
        ed:sleep(100)
        assert.equals(1, requests())
    end)

    it("keeps generic requests alive after focus and cursor changes", function()
        ed:server({ hover = "B", reply_delays = { 200 } }, "b")
        ed:lua [[
            _G.hover()
            vim.cmd.vsplit()
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
        ]]
        ed:sleep(400)
        assert.same({ "B @0:4" }, got())
    end)

    it("does not deliver to a window that no longer shows the buffer", function()
        ed:server({ hover = "B", reply_delays = { 200 } }, "b")
        ed:lua "_G.hover(); vim.cmd.enew()"
        ed:sleep(400)
        assert.same({}, got())
    end)
end)

describe("micro.lsp cursor context", function()
    local ed, log

    before_each(function()
        log = vim.fn.tempname()
        ed = Editor.new()
        ed:lua [[
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ééé xy", "other text" })
            vim.api.nvim_win_set_cursor(0, { 1, 7 })
            _G.got = {}
            function _G.ask(opts)
                require("micro.lsp").request_cursor("cursor", 0, "textDocument/hover", function(_, result)
                    if result then
                        table.insert(got, result.contents.value)
                        return true
                    end
                end, opts)
            end
        ]]
    end)
    after_each(function()
        ed:close()
        vim.fn.delete(log)
    end)

    local function got()
        return ed:lua "return _G.got"
    end
    local function requests()
        return vim.fn.filereadable(log) == 1 and #vim.fn.readfile(log) or 0
    end
    local function pending()
        ed:server({ hover = "B", reply_delays = { 300, 0 }, log = log }, "cursor")
        ed:lua "_G.ask()"
        assert.is_true(vim.wait(1000, function()
            return requests() == 1
        end, 10))
    end
    local function expired()
        ed:sleep(400) -- the server deliberately replies even after cancellation
        assert.same({}, got())
        ed:lua "_G.ask()"
        ed:wait "#_G.got == 1"
        assert.same({ "B @0:4" }, got())
    end

    for _, encoding in ipairs { { "utf-16", 4 }, { "utf-8", 7 } } do
        it("owns position construction for " .. encoding[1], function()
            ed:server({ hover = "B", encoding = encoding[1] }, "cursor")
            ed:lua "_G.ask { debounce = 50 }"
            ed:wait "#_G.got == 1"
            assert.same({ "B @0:" .. encoding[2] }, got())
        end)
    end

    it("retires a debounced request when focus leaves, even if it returns", function()
        ed:server({ hover = "B", log = log }, "cursor")
        ed:lua [[
            _G.ask { debounce = 100 }
            vim.cmd.vsplit()
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
            vim.cmd "wincmd p"
        ]]
        ed:sleep(250)
        assert.equals(0, requests())
        assert.same({}, got())
    end)

    it("retires an in-flight request when focus leaves and returns", function()
        pending()
        ed:lua [[vim.cmd.vsplit(); vim.cmd "wincmd p"]]
        expired()
    end)

    it("retires an in-flight request when the cursor moves and returns", function()
        pending()
        ed:input "h"
        ed:wait "vim.api.nvim_win_get_cursor(0)[2] == 6"
        ed:input "l"
        ed:wait "vim.api.nvim_win_get_cursor(0)[2] == 7"
        expired()
    end)

    it("retires an in-flight request when other text is edited and restored", function()
        pending()
        ed:lua [[
            vim.api.nvim_buf_set_lines(0, 1, 2, false, { "changed" })
            vim.api.nvim_buf_set_lines(0, 1, 2, false, { "other text" })
        ]]
        expired()
    end)

    it("retires a request when the owner changes buffers and returns", function()
        pending()
        ed:lua [[
            local buf = vim.api.nvim_get_current_buf()
            vim.cmd.enew()
            vim.api.nvim_win_set_buf(0, buf)
        ]]
        expired()
    end)

    it("keeps a fresh request created by the same cursor movement event", function()
        ed:server({ hover = "B", log = log }, "cursor")
        ed:lua [[
            vim.api.nvim_create_autocmd("CursorMoved", {
                callback = function() _G.ask { debounce = 50 } end,
            })
            _G.ask { debounce = 100 }
        ]]
        ed:input "h"
        ed:wait "#_G.got == 1"
        assert.same({ "B @0:3" }, got())
        assert.equals(1, requests())
    end)
end)

describe("LSP features on micro.lsp", function()
    local ed

    before_each(function()
        ed = Editor.new()
    end)
    after_each(function()
        ed:close()
    end)

    it("hover ignores a departed context and still displays a fresh reply", function()
        ed:lua [[
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hover" })
            require("micro.hover").setup {}
        ]]
        ed:server({ hover = "B", reply_delays = { 300, 0 } }, "hover")
        ed:lua [[
            require("micro.hover").show()
            vim.cmd.vsplit()
            vim.cmd "wincmd p"
        ]]
        ed:sleep(400)
        assert.is_true(ed:lua [[return require("micro.panel").get("eldoc") == nil]])
        ed:lua [[require("micro.hover").show()]]
        ed:wait [[require("micro.panel").get("eldoc") ~= nil]]
        assert.same(
            { "", "B @0:0", "" },
            ed:lua [[
            local _, buf = require("micro.panel").get("eldoc")
            return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        ]]
        )
    end)

    it("signature help without a client does not error", function()
        ed:lua [[require("micro.signature").setup {}]]
        ed:lua "vim.cmd 'PrintSignatureHelp'"
        assert.equals("", ed:lua "return vim.trim(vim.v.errmsg)")
    end)

    it("breadcrumbs matches the cursor against symbols in the client's encoding", function()
        local file = vim.fn.tempname() .. ".txt"
        vim.fn.writefile({ "ééé xy" }, file)
        local range = function(a, b)
            return { start = { line = 0, character = a }, ["end"] = { line = 0, character = b } }
        end
        -- breadcrumbs shows paths relative to the client root (the cwd), so keep the file under it
        ed:lua("vim.cmd.cd(vim.fs.dirname(...)); vim.cmd.edit(...)", file)
        ed:lua [[
            vim.notify = function() end
            vim.api.nvim_win_set_cursor(0, { 1, 7 })
        ]]
        ed:server({
            symbols = {
                { name = "Wide", kind = 12, range = range(0, 3), selectionRange = range(0, 3) },
                { name = "Target", kind = 12, range = range(4, 5), selectionRange = range(4, 5) },
            },
        }, "sym")
        ed:lua [[require("micro.breadcrumbs").enable()]]
        ed:wait "vim.wo.winbar:find('Target') ~= nil"
        vim.fn.delete(file)
    end)
end)
