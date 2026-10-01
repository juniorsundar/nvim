local Editor = require "tests.support.editor"

describe("micro.line_numbers", function()
    local ed

    before_each(function()
        ed = Editor.new()
        ed:lua [[
            vim.notify = function() end
            vim.wo.number, vim.wo.relativenumber = true, true
            require("micro.line_numbers").setup { dynamic = true }
            _G.nums = function()
                return { vim.wo.number, vim.wo.relativenumber }
            end
        ]]
    end)
    after_each(function()
        ed:close()
    end)

    local function nums()
        return ed:lua "return _G.nums()"
    end

    it("swaps relative for absolute numbers in insert mode", function()
        ed:input "i"
        ed:wait "vim.fn.mode() == 'i'"
        assert.same({ true, false }, nums())
        ed:input "<Esc>"
        ed:wait "vim.fn.mode() == 'n'"
        assert.same({ true, true }, nums())
    end)

    it("keeps numbers hidden through insert mode after toggling off", function()
        ed:lua "require('micro.line_numbers').toggle()"
        assert.same({ false, false }, nums())
        ed:input "i"
        ed:wait "vim.fn.mode() == 'i'"
        ed:input "<Esc>"
        ed:wait "vim.fn.mode() == 'n'"
        assert.same({ false, false }, nums())
        ed:lua "require('micro.line_numbers').toggle()"
        assert.same({ true, true }, nums())
    end)

    it("toggle shows both options together even when they were out of sync", function()
        ed:lua "vim.wo.relativenumber = false; require('micro.line_numbers').toggle()"
        assert.same({ false, false }, nums())
        ed:lua "require('micro.line_numbers').toggle()"
        assert.same({ true, true }, nums())
    end)

    it("leaves windows that only use absolute numbers alone", function()
        ed:lua "vim.wo.relativenumber = false"
        ed:input "i"
        ed:wait "vim.fn.mode() == 'i'"
        ed:input "<Esc>"
        ed:wait "vim.fn.mode() == 'n'"
        assert.same({ true, false }, nums())
    end)

    it("the toggle module's line number key uses it", function()
        ed:lua "require('micro.toggle').subcommands.toggle.line_numbers()"
        assert.same({ false, false }, nums())
    end)
end)
