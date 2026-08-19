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

describe("micro.pack gate (ready phase)", function()
    local stub_add

    before_each(function()
        package.loaded["micro.pack"] = nil
        stub_add = stub(vim.pack, "add")
    end)

    after_each(function()
        stub_add:revert()
    end)

    it("event fire drives prepare then setup lazily, and setup runs exactly once across repeated fires", function()
        local pack = require "micro.pack"
        local prepare_calls = 0
        local setup_calls = 0
        pack.add {
            src = "/tmp/plugins/ev1",
            name = "ev1",
            prepare = function()
                prepare_calls = prepare_calls + 1
            end,
            setup = function()
                setup_calls = setup_calls + 1
            end,
            event = { { "User", "MicroGateEv1" } },
        }
        assert.are.equal(0, setup_calls) -- nothing runs before the event
        assert.are.equal(0, prepare_calls)

        vim.cmd "doautocmd User MicroGateEv1"
        assert.are.equal(1, prepare_calls) -- prepare ran on event
        assert.are.equal(1, setup_calls) -- setup ran after prepare

        -- second event fire is a no-op: setup stays at exactly one invocation
        vim.cmd "doautocmd User MicroGateEv1"
        assert.are.equal(1, setup_calls)
        assert.are.equal(1, prepare_calls)
    end)

    it("ensure_ready forces prepare then setup synchronously without the event, and is idempotent", function()
        local pack = require "micro.pack"
        local prepare_calls = 0
        local setup_calls = 0
        pack.add {
            src = "/tmp/plugins/er1",
            name = "er1",
            prepare = function()
                prepare_calls = prepare_calls + 1
            end,
            setup = function()
                setup_calls = setup_calls + 1
            end,
        }
        assert.is_false(pack.is_prepared "er1")

        local ok, err = pack.ensure_ready "er1"
        assert.is_true(ok)
        assert.is_nil(err)
        assert.are.equal(1, prepare_calls)
        assert.are.equal(1, setup_calls)

        -- idempotent: a second call re-runs neither prepare nor setup
        local ok2, err2 = pack.ensure_ready "er1"
        assert.is_true(ok2)
        assert.is_nil(err2)
        assert.are.equal(1, prepare_calls)
        assert.are.equal(1, setup_calls)
    end)

    it("ensure_ready on a setup-only gate runs setup with no prepare work", function()
        local pack = require "micro.pack"
        local setup_calls = 0
        pack.add {
            src = "/tmp/plugins/eros",
            name = "eros",
            setup = function()
                setup_calls = setup_calls + 1
            end,
        }
        local ok, err = pack.ensure_ready "eros"
        assert.is_true(ok)
        assert.is_nil(err)
        assert.are.equal(1, setup_calls)
    end)

    it(
        "setup failure leaves the gate prepared but not ready; first ensure_ready returns (false, err), later calls re-throw",
        function()
            local pack = require "micro.pack"
            pack.add {
                src = "/tmp/plugins/sf1",
                name = "sf1",
                prepare = function() end,
                setup = function()
                    error "setup exploded"
                end,
            }
            local ok, err = pack.ensure_ready "sf1"
            assert.is_false(ok)
            -- raised errors carry a location prefix, so match by substring (02 convention)
            assert.truthy(tostring(err):find("setup exploded", 1, true))
            -- the artifact phase succeeded: prepared, but not ready
            assert.is_true(pack.is_prepared "sf1")
            assert.is_false(pack.is_ready "sf1")

            -- later calls re-throw the stored setup error
            local retry_ok, retry_err = pcall(pack.ensure_ready, "sf1")
            assert.is_false(retry_ok)
            assert.truthy(tostring(retry_err):find("setup exploded", 1, true))
        end
    )

    it(
        "on_ready fires (true, nil) when the gate becomes ready and immediately with the stored outcome after settlement",
        function()
            local pack = require "micro.pack"
            local before
            pack.add {
                src = "/tmp/plugins/or1",
                name = "or1",
                prepare = function() end,
                setup = function() end,
            }
            pack.on_ready("or1", function(ok, err)
                before = { ok, err }
            end)
            assert.is_nil(before) -- not ready yet
            pack.ensure_ready "or1"
            assert.same({ true, nil }, before)

            local after
            pack.on_ready("or1", function(ok, err)
                after = { ok, err }
            end)
            assert.same({ true, nil }, after) -- immediate, stored outcome
        end
    )

    it(
        "on_ready fires (false, err) on setup failure and on prepare failure, with setup never run after a failed prepare",
        function()
            local pack = require "micro.pack"
            local setup_fail
            pack.add {
                src = "/tmp/plugins/or2",
                name = "or2",
                prepare = function() end,
                setup = function()
                    error "setup broke"
                end,
            }
            local setup_calls = 0
            pack.add {
                src = "/tmp/plugins/or3",
                name = "or3",
                prepare = function()
                    error "prepare broke"
                end,
                setup = function()
                    setup_calls = setup_calls + 1
                end,
            }
            pack.on_ready("or2", function(ok, err)
                setup_fail = { ok, err }
            end)
            local prepare_fail
            pack.on_ready("or3", function(ok, err)
                prepare_fail = { ok, err }
            end)
            pack.ensure_ready "or2"
            pack.ensure_ready "or3"
            assert.is_false(setup_fail[1])
            assert.truthy(tostring(setup_fail[2]):find("setup broke", 1, true))
            assert.is_false(prepare_fail[1])
            assert.truthy(tostring(prepare_fail[2]):find("prepare broke", 1, true))
            assert.are.equal(0, setup_calls) -- setup never runs after a failed prepare
        end
    )

    it("on_ready is a pure observer and never starts work", function()
        local pack = require "micro.pack"
        local prepare_calls = 0
        local setup_calls = 0
        pack.add {
            src = "/tmp/plugins/or4",
            name = "or4",
            prepare = function()
                prepare_calls = prepare_calls + 1
            end,
            setup = function()
                setup_calls = setup_calls + 1
            end,
        }
        pack.on_ready("or4", function() end)
        assert.are.equal(0, prepare_calls)
        assert.are.equal(0, setup_calls)
        assert.is_false(pack.is_ready "or4")
    end)

    it("event fire with a failing prepare never runs setup and settles on_ready with (false, err)", function()
        local pack = require "micro.pack"
        local setup_calls = 0
        local ready_cb
        pack.add {
            src = "/tmp/plugins/evfail",
            name = "evfail",
            prepare = function()
                error "build exploded on event"
            end,
            setup = function()
                setup_calls = setup_calls + 1
            end,
            event = { { "User", "MicroGateEvFail" } },
        }
        pack.on_ready("evfail", function(ok, err)
            ready_cb = { ok, err }
        end)
        vim.cmd "doautocmd User MicroGateEvFail"
        assert.are.equal(0, setup_calls) -- setup never runs after a failed prepare
        assert.is_false(ready_cb[1])
        assert.truthy(tostring(ready_cb[2]):find("build exploded on event", 1, true))
        assert.is_false(pack.is_prepared "evfail")
        assert.is_false(pack.is_ready "evfail")
    end)

    it("is_ready is nil for an absent gate, false before ready, true once prepared and setup done", function()
        local pack = require "micro.pack"
        assert.is_nil(pack.is_ready "absent-gate")

        pack.add {
            src = "/tmp/plugins/ir1",
            name = "ir1",
            prepare = function() end,
            setup = function() end,
        }
        assert.is_false(pack.is_ready "ir1") -- gate exists, not ready yet
        pack.ensure_ready "ir1"
        assert.is_true(pack.is_ready "ir1")
    end)

    it("event success marks the gate ready and settles on_ready with (true, nil)", function()
        local pack = require "micro.pack"
        local ready_cb
        pack.add {
            src = "/tmp/plugins/ev2",
            name = "ev2",
            prepare = function() end,
            setup = function() end,
            event = { { "User", "MicroGateEv2" } },
        }
        pack.on_ready("ev2", function(ok, err)
            ready_cb = { ok, err }
        end)
        assert.is_false(pack.is_ready "ev2")
        vim.cmd "doautocmd User MicroGateEv2"
        assert.is_true(pack.is_ready "ev2")
        assert.same({ true, nil }, ready_cb)
    end)

    it("event then ensure_ready interleaving still runs prepare and setup exactly once total", function()
        local pack = require "micro.pack"
        local prepare_calls = 0
        local setup_calls = 0
        pack.add {
            src = "/tmp/plugins/ev3",
            name = "ev3",
            prepare = function()
                prepare_calls = prepare_calls + 1
            end,
            setup = function()
                setup_calls = setup_calls + 1
            end,
            event = { { "User", "MicroGateEv3" } },
        }
        vim.cmd "doautocmd User MicroGateEv3"
        local ok, err = pack.ensure_ready "ev3"
        assert.is_true(ok)
        assert.is_nil(err)
        assert.are.equal(1, prepare_calls)
        assert.are.equal(1, setup_calls) -- the ensure after the event did not re-run setup

        -- reverse order: ensure_ready first, then the event fires
        local rev_p, rev_s = 0, 0
        pack.add {
            src = "/tmp/plugins/ev3r",
            name = "ev3r",
            prepare = function()
                rev_p = rev_p + 1
            end,
            setup = function()
                rev_s = rev_s + 1
            end,
            event = { { "User", "MicroGateEv3r" } },
        }
        local ok2 = pack.ensure_ready "ev3r"
        assert.is_true(ok2)
        vim.cmd "doautocmd User MicroGateEv3r"
        assert.are.equal(1, rev_p)
        assert.are.equal(1, rev_s) -- the event after the ensure did not re-run setup
    end)

    it("multiple event entries are once-across-any: first fire wins, the rest no-op", function()
        local pack = require "micro.pack"
        local prepare_calls = 0
        local setup_calls = 0
        pack.add {
            src = "/tmp/plugins/ev4",
            name = "ev4",
            prepare = function()
                prepare_calls = prepare_calls + 1
            end,
            setup = function()
                setup_calls = setup_calls + 1
            end,
            event = { { "User", "MicroGateA" }, { "User", "MicroGateB" } },
        }
        vim.cmd "doautocmd User MicroGateA"
        assert.are.equal(1, setup_calls)
        assert.are.equal(1, prepare_calls)
        assert.is_true(pack.is_ready "ev4")
        vim.cmd "doautocmd User MicroGateB" -- second entry: no-op
        assert.are.equal(1, setup_calls)
        assert.are.equal(1, prepare_calls)
    end)

    it("setup failure keeps the on_prepared success outcome (true, nil)", function()
        local pack = require "micro.pack"
        local prepared_cb
        pack.add {
            src = "/tmp/plugins/sf2",
            name = "sf2",
            prepare = function() end,
            setup = function()
                error "setup broke again"
            end,
        }
        pack.on_prepared("sf2", function(ok, err)
            prepared_cb = { ok, err }
        end)
        local ok, err = pack.ensure_ready "sf2"
        assert.is_false(ok)
        assert.truthy(tostring(err):find("setup broke again", 1, true))
        -- the prepared phase succeeded and its observers saw success
        assert.is_true(prepared_cb[1])
        assert.is_nil(prepared_cb[2])
        assert.is_true(pack.is_prepared "sf2")
        assert.is_false(pack.is_ready "sf2")
    end)

    it("on_ready registered after settlement fires immediately with the stored failure outcome", function()
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/or5",
            name = "or5",
            prepare = function() end,
            setup = function()
                error "late setup broke"
            end,
        }
        pack.add {
            src = "/tmp/plugins/or6",
            name = "or6",
            prepare = function()
                error "late prepare broke"
            end,
            setup = function() end,
        }
        pack.ensure_ready "or5"
        pack.ensure_ready "or6"

        local late_setup
        pack.on_ready("or5", function(ok, err)
            late_setup = { ok, err }
        end)
        assert.is_false(late_setup[1])
        assert.truthy(tostring(late_setup[2]):find("late setup broke", 1, true))

        local late_prepare
        pack.on_ready("or6", function(ok, err)
            late_prepare = { ok, err }
        end)
        assert.is_false(late_prepare[1])
        assert.truthy(tostring(late_prepare[2]):find("late prepare broke", 1, true))
    end)

    it("event path awaits an async (thenable) prepare before running setup", function()
        local pack = require "micro.pack"
        local order = {}
        local t = {
            status = "pending",
            pwait = function(self)
                self.status = "succeeded"
                table.insert(order, "pwait")
                return true
            end,
            map = function(self, cb)
                vim.schedule(cb)
            end,
        }
        pack.add {
            src = "/tmp/plugins/ev5",
            name = "ev5",
            prepare = function()
                table.insert(order, "prepare")
                return t
            end,
            setup = function()
                table.insert(order, "setup")
            end,
            event = { { "User", "MicroGateEv5" } },
        }
        vim.cmd "doautocmd User MicroGateEv5"
        assert.same({ "prepare", "pwait", "setup" }, order) -- setup only after the thenable settled
        assert.equal("succeeded", t.status)
        assert.is_true(pack.is_ready "ev5")
    end)

    it("event-path setup failure: first ensure_ready returns (false, err), the second re-throws", function()
        local pack = require "micro.pack"
        pack.add {
            src = "/tmp/plugins/sf3",
            name = "sf3",
            prepare = function() end,
            setup = function()
                error "event setup broke"
            end,
            event = { { "User", "MicroGateSf3" } },
        }
        vim.cmd "doautocmd User MicroGateSf3"

        local ok, err = pack.ensure_ready "sf3"
        assert.is_false(ok)
        assert.truthy(tostring(err):find("event setup broke", 1, true))
        local retry_ok, retry_err = pcall(pack.ensure_ready, "sf3")
        assert.is_false(retry_ok)
        assert.truthy(tostring(retry_err):find("event setup broke", 1, true))
        -- the gate remains prepared, not ready
        assert.is_true(pack.is_prepared "sf3")
        assert.is_false(pack.is_ready "sf3")
    end)

    it("passes the context { name, path, spec } (path sourced via vim.pack.get) to prepare and setup", function()
        local stub_get = stub(vim.pack, "get").returns {
            { spec = { name = "ctxg", src = "https://example.com/ctxg" }, path = "/tmp/plugins/ctxg" },
        }
        local pack = require "micro.pack"
        local pctx, sctx
        pack.add {
            src = "/tmp/plugins/ctxg",
            name = "ctxg",
            prepare = function(ctx)
                pctx = ctx
            end,
            setup = function(ctx)
                sctx = ctx
            end,
        }
        local ok, err = pack.ensure_ready "ctxg"
        stub_get:revert()
        assert.is_true(ok)
        assert.is_nil(err)

        -- both callbacks receive the same context
        assert.is_not_nil(pctx)
        assert.is_not_nil(sctx)
        assert.equal("ctxg", pctx.name)
        assert.equal("/tmp/plugins/ctxg", pctx.path)
        assert.equal("ctxg", sctx.name)
        assert.equal("/tmp/plugins/ctxg", sctx.path)
        assert.is_table(pctx.spec)
        assert.is_table(sctx.spec)
    end)
end)
