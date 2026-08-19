local stub = require "luassert.stub"

describe("micro.pack", function()
    describe("harness", function()
        it("loads under the plenary test harness", function()
            local pack = require "micro.pack"
            assert.is_table(pack)
        end)
    end)

    describe("vim.pack.get seam", function()
        local stub_get
        local stub_add

        before_each(function()
            package.loaded["micro.pack"] = nil
            stub_get = stub(vim.pack, "get").returns {
                { spec = { name = "blink.cmp", src = "https://github.com/saghen/blink.cmp" } },
            }
            stub_add = stub(vim.pack, "add")
        end)

        after_each(function()
            stub_get:revert()
            stub_add:revert()
        end)

        it("lets code under test observe a stubbed vim.pack.get", function()
            local pack = require "micro.pack"
            pack.add "https://github.com/saghen/blink.cmp"
            assert.same({ healthy = { "blink.cmp" }, missing = {}, errors = {} }, pack.health())
        end)
    end)
end)
