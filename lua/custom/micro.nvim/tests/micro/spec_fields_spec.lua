-- ---------------------------------------------------------------------------
-- micro.pack spec-field contract used by the user's config wiring (issue 06).
--
-- These tests are deliberately generic: they never name a concrete plugin, so
-- the wrapper stays standalone. They pin the contract the config relies on —
-- that a spec carrying gate fields (event/prepare/setup) is forwarded intact to
-- vim.pack.add, that prepare returns a duck-typed thenable when the module's
-- build does, and that the event field's plain string entries each register
-- exactly one once-autocmd. The event cycle itself is exercised end-to-end in
-- the existing suite; these tests only pin the field contract.
-- ---------------------------------------------------------------------------

describe("micro.pack spec-field contract", function()
    local original_add
    local added_specs

    local function autocmd_ids(event)
        return vim.api.nvim_get_autocmds { event = event }
    end

    local function id_set(event)
        local out = {}
        for _, a in ipairs(autocmd_ids(event)) do
            out[a.id] = true
        end
        return out
    end

    -- deleted in after_each so no autocmd leaks into later tests
    local created = {}

    before_each(function()
        package.loaded["micro.pack"] = nil
        created = {}
        added_specs = nil
        original_add = vim.pack.add
        vim.pack.add = function(specs)
            added_specs = specs
        end
    end)

    after_each(function()
        for _, id in ipairs(created) do
            pcall(vim.api.nvim_del_autocmd, id)
        end
        vim.pack.add = original_add
    end)

    local function ids_created_between(before, after)
        local new = {}
        for id in pairs(after) do
            if not before[id] then
                table.insert(new, id)
            end
        end
        return new
    end

    describe("gate fields reach vim.pack.add intact", function()
        it("event/prepare/setup survive the add/normalise path", function()
            local pack = require "micro.pack"
            local prepare = function() end
            local setup = function() end
            pack.add {
                src = "/tmp/plugins/contract-one",
                name = "contract-one",
                event = { "CmdlineEnter", "LspAttach" },
                prepare = prepare,
                setup = setup,
            }

            assert.is_table(added_specs)
            assert.are.equal(1, #added_specs)
            local spec = added_specs[1]
            assert.equal("contract-one", spec.name)
            -- src is expanded by micro.pack, the gate fields pass through verbatim
            assert.same({ "CmdlineEnter", "LspAttach" }, spec.event)
            assert.equal(prepare, spec.prepare)
            assert.equal(setup, spec.setup)
        end)

        it("a plain spec (no gate fields) is forwarded with no event entry", function()
            local pack = require "micro.pack"
            pack.add { src = "/tmp/plugins/contract-plain", name = "contract-plain" }

            assert.is_table(added_specs)
            assert.are.equal(1, #added_specs)
            assert.is_nil(added_specs[1].event)
            assert.is_nil(added_specs[1].prepare)
            assert.is_nil(added_specs[1].setup)
        end)
    end)

    describe("prepare returns a duck-typed thenable", function()
        it("a module build returning a task satisfies the gate's thenable contract", function()
            -- a generic stand-in for any plugin's lazy build entry point
            local task = {
                status = "pending",
                pwait = function(self)
                    self.status = "succeeded"
                    return true
                end,
                map = function(self, cb)
                    vim.schedule(cb)
                end,
            }
            package.loaded["sample.build.stub"] = {
                build = function()
                    return task
                end,
            }
            package.loaded["micro.pack"] = nil

            local pack = require "micro.pack"
            pack.add {
                src = "/tmp/plugins/contract-thenable",
                name = "contract-thenable",
                prepare = function()
                    return require("sample.build.stub").build()
                end,
            }

            local spec = added_specs[1]
            local ok, ret = pcall(spec.prepare)
            assert.is_true(ok)
            assert.equal(task, ret) -- the gate receives the exact build task
            -- duck-typed thenable per CONTEXT.md: :pwait() plus (:map or .status)
            assert.is_function(ret.pwait)
            assert.is_function(ret.map)
            assert.is_not_nil(ret.status)
        end)

        it("a synchronous (non-thenable) prepare return is accepted", function()
            local pack = require "micro.pack"
            pack.add {
                src = "/tmp/plugins/contract-sync",
                name = "contract-sync",
                prepare = function()
                    return true
                end,
            }
            local spec = added_specs[1]
            local ok, ret = pcall(spec.prepare)
            assert.is_true(ok)
            assert.is_true(ret)
        end)
    end)

    describe("event field registers one once-autocmd per plain string entry", function()
        it("two string events create exactly one autocmd for each", function()
            local pack = require "micro.pack"
            local before_cmdline = id_set "CmdlineEnter"
            local before_attach = id_set "LspAttach"

            pack.add {
                src = "/tmp/plugins/contract-events",
                name = "contract-events",
                event = { "CmdlineEnter", "LspAttach" },
                prepare = function() end,
            }

            local after_cmdline = id_set "CmdlineEnter"
            local after_attach = id_set "LspAttach"

            local new_cmdline = ids_created_between(before_cmdline, after_cmdline)
            local new_attach = ids_created_between(before_attach, after_attach)

            assert.are.equal(1, #new_cmdline) -- exactly one CmdlineEnter autocmd
            assert.are.equal(1, #new_attach) -- exactly one LspAttach autocmd
            vim.list_extend(created, new_cmdline)
            vim.list_extend(created, new_attach)
        end)

        it("a spec without event creates no autocmds", function()
            local pack = require "micro.pack"
            local before_cmdline = id_set "CmdlineEnter"

            pack.add { src = "/tmp/plugins/contract-noevent", name = "contract-noevent" }

            local after_cmdline = id_set "CmdlineEnter"
            assert.are.equal(0, #ids_created_between(before_cmdline, after_cmdline))
        end)
    end)
end)
