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

describe("micro.pack gate (prepared phase)", function()
    local stub_add

    before_each(function()
        package.loaded["micro.pack"] = nil
        stub_add = stub(vim.pack, "add")
    end)

    after_each(function()
        stub_add:revert()
    end)

    local function add_gated(name)
        local pack = require "micro.pack"
        pack.add { src = "/tmp/plugins/" .. name, name = name, prepare = function() end }
        return pack
    end

    it("is_prepared returns false before prepare, nil for a name with no gate", function()
        local pack = add_gated "gated"
        assert.is_false(pack.is_prepared "gated")
        assert.is_nil(pack.is_prepared "unknown")
        pack.add { src = "/tmp/plugins/plain", name = "plain" }
        assert.is_nil(pack.is_prepared "plain") -- no gate fields → no gate, behaves as today
    end)

    it("ensure_prepared runs a sync prepare, returns (true, nil), never runs setup, and is idempotent", function()
        local prepare_calls = 0
        local setup_calls = 0
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/syncp",
            name = "syncp",
            prepare = function()
                prepare_calls = prepare_calls + 1
            end,
            setup = function()
                setup_calls = setup_calls + 1
            end,
        }
        local ok, err = pack.ensure_prepared "syncp"
        assert.is_true(ok)
        assert.is_nil(err)
        assert.is_true(pack.is_prepared "syncp")
        assert.are.equal(0, setup_calls) -- ensure_prepared never runs setup
        local ok2, err2 = pack.ensure_prepared "syncp"
        assert.is_true(ok2)
        assert.is_nil(err2)
        assert.are.equal(1, prepare_calls) -- idempotent: second call does not re-run prepare
    end)

    -- duck-typed fake thenable per CONTEXT.md: :pwait() + :map(cb)
    local function fake_thenable(ok, err)
        local t = { status = "pending", waited = false }
        function t:pwait()
            self.waited = true
            self.status = ok and "succeeded" or "failed"
            if not ok then
                return false, err
            end
            return true
        end
        function t:map(cb)
            vim.schedule(cb)
        end
        return t
    end

    it("awaits a duck-typed thenable returned by prepare (success)", function()
        local built
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/asyncok",
            name = "asyncok",
            prepare = function()
                built = fake_thenable(true)
                return built
            end,
        }
        local ok, err = pack.ensure_prepared "asyncok"
        assert.is_true(built.waited) -- :pwait() was called on the thenable
        assert.is_true(ok)
        assert.is_nil(err)
        assert.is_true(pack.is_prepared "asyncok")
    end)

    it("treats a plain (non-thenable) prepare return as synchronous success", function()
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/plainret",
            name = "plainret",
            prepare = function()
                return 42
            end,
        }
        local ok, err = pack.ensure_prepared "plainret"
        assert.is_true(ok)
        assert.is_nil(err)
        assert.is_true(pack.is_prepared "plainret")
    end)

    it("failed prepare: ensure returns (false, err), is_prepared is false, later calls re-throw", function()
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/failing",
            name = "failing",
            prepare = function()
                return fake_thenable(false, "libblink build failed")
            end,
        }
        local ok, err = pack.ensure_prepared "failing"
        assert.is_false(ok)
        assert.equal("libblink build failed", err)
        assert.is_false(pack.is_prepared "failing")
        local retry_ok, retry_err = pcall(pack.ensure_prepared, "failing")
        assert.is_false(retry_ok) -- stored error is re-thrown (with a location prefix)
        assert.truthy(tostring(retry_err):find("libblink build failed", 1, true))
    end)

    it("distinguishes plugin absent (no gate) from prepare failed", function()
        local pack = require "micro.pack"
        local ok, err = pack.ensure_prepared "never-declared"
        assert.is_false(ok)
        -- distinct, informative "absent" error — no prepare was ever attempted
        assert.truthy(tostring(err):find("no gate", 1, true))
        assert.is_nil(pack.is_prepared "never-declared")

        -- contrast with a failed prepare
        pack.add {
            src = "/tmp/plugins/failing2",
            name = "failing2",
            prepare = function()
                error "build exploded"
            end,
        }
        local ok2, err2 = pack.ensure_prepared "failing2"
        assert.is_false(ok2)
        assert.truthy(tostring(err2):find("build exploded", 1, true))
        assert.is_not_nil(err2)
        assert.are_not.equal(tostring(err), tostring(err2)) -- distinct signals
    end)

    it("prepare is invoked exactly once across repeated calls with a thenable prepare", function()
        local prepare_calls = 0
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/joinp",
            name = "joinp",
            prepare = function()
                prepare_calls = prepare_calls + 1
                return fake_thenable(true)
            end,
        }
        local ok1, err1 = pack.ensure_prepared "joinp"
        local ok2, err2 = pack.ensure_prepared "joinp"
        assert.is_true(ok1)
        assert.is_true(ok2)
        assert.is_nil(err1)
        assert.is_nil(err2)
        assert.are.equal(1, prepare_calls) -- joins the stored outcome, never a second prepare
    end)

    it("on_prepared fires (true, nil) after a successful settle and (false, err) after a failure", function()
        local pack = require "micro.pack"
        local ok1, ok2, err1, err2
        pack.add {
            src = "/tmp/plugins/obs1",
            name = "obs1",
            prepare = function()
                return fake_thenable(true)
            end,
        }
        pack.add {
            src = "/tmp/plugins/obs2",
            name = "obs2",
            prepare = function()
                return fake_thenable(false, "obs2 broken")
            end,
        }
        -- registered before settlement
        pack.on_prepared("obs1", function(ok, err)
            ok1, err1 = ok, err
        end)
        pack.on_prepared("obs2", function(ok, err)
            ok2, err2 = ok, err
        end)
        pack.ensure_prepared "obs1"
        pack.ensure_prepared "obs2"
        assert.is_true(ok1)
        assert.is_nil(err1)
        assert.is_false(ok2)
        assert.equal("obs2 broken", err2)
    end)

    it("on_prepared registered after settlement fires immediately with the stored outcome", function()
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/obs3",
            name = "obs3",
            prepare = function()
                return fake_thenable(true)
            end,
        }
        pack.ensure_prepared "obs3"
        local fired = nil
        pack.on_prepared("obs3", function(ok, err)
            fired = { ok, err }
        end)
        assert.is_true(fired[1])
        assert.is_nil(fired[2])
    end)

    it("on_prepared never starts prepare", function()
        local prepare_calls = 0
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/obs4",
            name = "obs4",
            prepare = function()
                prepare_calls = prepare_calls + 1
                return fake_thenable(true)
            end,
        }
        local fired = false
        pack.on_prepared("obs4", function()
            fired = true
        end)
        assert.are.equal(0, prepare_calls) -- registering the observer did not kick off work
        assert.is_false(fired)
        assert.is_false(pack.is_prepared "obs4")
    end)

    it("awaits a thenable exposing :pwait() + .status but no :map (either duck-type counts)", function()
        local built
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/statusonly",
            name = "statusonly",
            prepare = function()
                built = { status = "pending" }
                function built:pwait()
                    self.status = "succeeded"
                    return true
                end
                return built
            end,
        }
        local ok, err = pack.ensure_prepared "statusonly"
        assert.is_true(ok)
        assert.is_nil(err)
        assert.equal("succeeded", built.status)
        assert.is_true(pack.is_prepared "statusonly")
    end)

    it("joins an in-flight thenable rather than starting a second prepare", function()
        local prepare_calls = 0
        local order = {}
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/joinlive",
            name = "joinlive",
            prepare = function()
                prepare_calls = prepare_calls + 1
                local t = {
                    status = "pending",
                    pwait = function(self)
                        self.calls = (self.calls or 0) + 1
                        table.insert(order, "pwait-" .. self.calls)
                        if self.calls > 1 then
                            -- the joining caller resolves the in-flight wait
                            self.resolved = true
                            return true
                        end
                        -- first caller blocks until the join resolves it
                        vim.wait(5000, function()
                            return self.resolved
                        end)
                        return true
                    end,
                    map = function(self, cb)
                        vim.schedule(cb)
                    end,
                }
                return t
            end,
        }
        local second_ok, second_err
        vim.schedule(function()
            second_ok, second_err = pack.ensure_prepared "joinlive"
        end)
        local first_ok, first_err = pack.ensure_prepared "joinlive"
        assert.is_true(first_ok)
        assert.is_nil(first_err)
        assert.is_true(second_ok) -- the scheduled join ran while the first was blocked
        assert.is_nil(second_err)
        assert.are.equal(1, prepare_calls) -- one prepare, two joined callers
        -- first caller entered pwait, then the join entered, then the first unblocked
        assert.same({ "pwait-1", "pwait-2" }, order)
    end)

    it("creates a gate for setup-only and event-only specs; ensure is a no-op success", function()
        local pack = require "micro.pack"
        pack.add { src = "/tmp/plugins/setuponly", name = "setuponly", setup = function() end }
        pack.add { src = "/tmp/plugins/eventonly", name = "eventonly", event = "CmdlineEnter" }
        assert.is_false(pack.is_prepared "setuponly")
        assert.is_false(pack.is_prepared "eventonly")
        local ok1, err1 = pack.ensure_prepared "setuponly"
        local ok2, err2 = pack.ensure_prepared "eventonly"
        assert.is_true(ok1)
        assert.is_nil(err1)
        assert.is_true(ok2)
        assert.is_nil(err2)
    end)

    it("is_prepared never starts or blocks on work", function()
        local prepare_calls = 0
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/lazycheck",
            name = "lazycheck",
            prepare = function()
                prepare_calls = prepare_calls + 1
                error "should never run"
            end,
        }
        -- a probe that would raise if it ran work
        assert.is_false(pack.is_prepared "lazycheck")
        assert.is_false(pack.is_prepared "lazycheck")
        assert.are.equal(0, prepare_calls)
    end)
end)
