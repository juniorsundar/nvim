# 02 — Gate core: prepared phase

**What to build:** The readiness gate is created when an `M.add` spec carries gate fields, and the **prepared** phase works end-to-end. `prepare` may return synchronously or a duck-typed thenable (has `:pwait()` and (`:map` or `.status`)). `M.ensure_prepared(name)` forces `prepare` to run and `:pwait`s the thenable, returning `(ok, err)` — `true` on prepared, `false` on failed with the stored error, and a distinct result when the plugin is absent (no gate exists). `M.is_prepared(name)` is a cheap, non-blocking observer returning `true`/`false`/`nil`. `M.on_prepared(name, cb)` is a pure observer firing `cb(ok, err)` immediately if the gate is already settled, otherwise on settlement. Failure stores the error and fires `on_prepared` cbs with `(false, err)`. `ensure_prepared` is idempotent and joins an in-flight thenable rather than starting a duplicate. Gates are keyed by `spec.name`; specs without gate fields create no gate (backward compatible). `ensure_prepared` **never** runs `setup`.

**Blocked by:** 01 — Test harness for micro.pack.

**Status:** ready-for-agent

- [ ] Calling `M.add` with a spec carrying a gate field creates a gate for that plugin; a spec without gate fields creates no gate and behaves exactly as today.
- [ ] `M.is_prepared(name)` returns `false` before prepare, `true` after a synchronous-success `prepare`, `nil` for an unknown name, and `false` after a failed prepare. It never starts or blocks on work.
- [ ] `M.ensure_prepared(name)` on an idle gate runs `prepare` and returns `(true, nil)` for a sync-success prepare.
- [ ] `M.ensure_prepared(name)` on a gate with an async (thenable) `prepare` `:pwait`s and returns the thenable's outcome.
- [ ] `M.ensure_prepared(name)` does **not** run `setup` (a stubbed `setup` is never called by it).
- [ ] `M.ensure_prepared(name)` is idempotent: a second call returns the stored outcome without re-running `prepare`.
- [ ] `M.ensure_prepared(name)` joins an in-flight thenable rather than starting a second `prepare` (`prepare` stub invoked once across two concurrent calls).
- [ ] When `prepare` fails, the gate enters the failed state with the stored error; `ensure_prepared` returns `(false, err)` and re-throws the stored error on subsequent calls.
- [ ] `M.ensure_prepared(name)` distinguishes "plugin absent" (no gate) from "prepare failed" via its `(ok, err)` return.
- [ ] `M.on_prepared(name, cb)` registered before settlement fires `(true, nil)` on success / `(false, err)` on failure; registered after settlement fires immediately with the stored outcome; it never starts `prepare`.
- [ ] A `prepare` return with `:pwait()` + (`:map` or `.status`) is awaited; a `nil`/non-thenable return is treated as synchronous success.