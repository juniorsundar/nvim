# 03 — Ready phase: event-triggered setup

**What to build:** The **ready** phase on top of the prepared gate. An `event` (string or list) declared on a spec creates a single per-gate autocmd, `once = true` across all listed events. Whichever event fires first runs `prepare` → `setup` → marks the gate ready, then the autocmd self-deletes. `setup` runs **only** on `event` — never as a side effect of `ensure_prepared` — preserving the owner's lazy-loading strategy. A `setup` failure leaves the gate `prepared` but not `ready`; `on_ready` cbs fire `(false, err)`, while `on_prepared` cbs already fired `(true, nil)`. `M.ensure_ready(name)` forces `prepare` then `setup` to run and complete (may block). `M.on_ready(name, cb)` fires after prepared + setup, or immediately with the stored outcome if already settled.

**Blocked by:** 02 — Gate core: prepared phase.

**Status:** ready-for-agent

- [ ] A spec with `event` set creates a single autocmd, once-across-any of the listed events; the first event to fire runs `prepare` → `setup` → marks the gate ready.
- [ ] `setup` runs exactly once, after `prepare` succeeds, triggered by `event`.
- [ ] `setup` is **not** run by `ensure_prepared` (the prepared-phase ticket already asserts this; here we assert `event`-triggered `setup` works and that forcing prepared alone never configured the plugin).
- [ ] A second event fire is a no-op (the autocmd self-deletes after the first fire).
- [ ] If `prepare` fails on the event path, `setup` never runs.
- [ ] If `setup` errors, the gate is `prepared` but not `ready`: `is_prepared` returns `true`, the ready surface reports not-ready with the stored error, and `on_prepared` cbs already fired `(true, nil)`.
- [ ] `M.on_ready(name, cb)` registered before settlement fires `(true, nil)` on success / `(false, err)` on setup failure; registered after settlement fires immediately with the stored outcome.
- [ ] `M.ensure_ready(name)` forces `prepare` then `setup` to run and complete and returns `(ok, err)`.
- [ ] `event` is driven in tests via `vim.api.nvim_exec_autocmds` (or equivalent), asserting the full prepare→setup→ready transition.