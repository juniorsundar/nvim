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

    it("does not deliver to a window that no longer shows the buffer", function()
        ed:server({ hover = "B", reply_delays = { 200 } }, "b")
        ed:lua "_G.hover(); vim.cmd.enew()"
        ed:sleep(400)
        assert.same({}, got())
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
