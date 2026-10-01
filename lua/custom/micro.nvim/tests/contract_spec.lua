local Editor = require "tests.support.editor"

describe("micro module contract", function()
    local ed

    before_each(function()
        ed = Editor.new()
    end)
    after_each(function()
        ed:close()
    end)

    it("setup merges from defaults each call, not into the previous config", function()
        local r = ed:lua [[
            local toggle = require "micro.toggle"
            toggle.setup { toggle_prefix = "<leader>X" }
            toggle.setup {}
            local function has(lhs)
                return vim.fn.maparg(vim.keycode(lhs), "n") ~= ""
            end
            -- the second call must fall back to the default prefix for new maps
            return { default = has "<localleader>Tn" }
        ]]
        assert.same({ default = true }, r)
    end)

    it("loading statusline and quickfix changes no options", function()
        local r = ed:lua [[
            local before = { vim.o.statusline, vim.o.scrolloff, vim.o.qftf, vim.g.micro_statusline }
            require "micro.statusline"
            require "micro.quickfix"
            local after = { vim.o.statusline, vim.o.scrolloff, vim.o.qftf, vim.g.micro_statusline }
            return vim.deep_equal(before, after)
        ]]
        assert.is_true(r)
    end)

    it("quickfix setup installs its text function", function()
        ed:lua [[
            require("micro.quickfix").setup()
            vim.fn.setqflist({ { filename = "a.lua", lnum = 3, col = 1, text = "hi", type = "E" } })
            vim.cmd.copen()
        ]]
        assert.truthy(ed:lua("return vim.fn.getline(1)"):find "a.lua")
    end)

    it("breadcrumbs toggle works without breadcrumbs being set up", function()
        local r = ed:lua [[
            vim.notify = function() end
            local b = require "micro.breadcrumbs"
            b.toggle()
            local on = #vim.api.nvim_get_autocmds { group = "Breadcrumbs" } > 0
            b.toggle()
            local off = pcall(vim.api.nvim_get_autocmds, { group = "Breadcrumbs" })
            return { on = on, off = off }
        ]]
        assert.same({ on = true, off = false }, r)
    end)

    it("micro no longer creates vim.Micro", function()
        ed:lua [[require("micro").setup { hover = { enabled = true } }]]
        assert.is_true(ed:lua "return vim.Micro == nil")
    end)
end)
