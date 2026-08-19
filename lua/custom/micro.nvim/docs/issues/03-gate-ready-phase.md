# 03 — Ready phase: event-triggered setup

**What to build:** The **ready** phase on top of the prepared gate. An `event` (string or list) declared on a spec creates a single per-gate autocmd, `once = true` across all listed events. Whichever event fires first runs `prepare` → `setup` → marks the gate ready, then the autocmd self-deletes. `setup` runs **only** on `event` — never as a side effect of `ensure_prepared` — preserving the owner's lazy-loading strategy. A `setup` failure leaves the gate `prepared` but not `ready`; `on_ready` cbs fire `(false, err)`, while `on_prepared` cbs already fired `(true, nil)`. `M.ensure_ready(name)` forces `prepare` then `setup` to run and complete (may block). `M.on_ready(name, cb)` fires after prepared + setup, or immediately with the stored outcome if already settled.

**Blocked by:** 02 — Gate core: prepared phase.

**Status:** done

- [X] A spec with `event` set creates a single autocmd, once-across-any of the listed events; the first event to fire runs `prepare` → `setup` → marks the gate ready.
- [X] `setup` runs exactly once, after `prepare` succeeds, triggered by `event`.
- [X] `setup` is **not** run by `ensure_prepared` (the prepared-phase ticket already asserts this; here we assert `event`-triggered `setup` works and that forcing prepared alone never configured the plugin).
- [X] A second event fire is a no-op (the autocmd self-deletes after the first fire).
- [X] If `prepare` fails on the event path, `setup` never runs.
- [X] If `setup` errors, the gate is `prepared` but not `ready`: `is_prepared` returns `true`, the ready surface reports not-ready with the stored error, and `on_prepared` cbs already fired `(true, nil)`.
- [X] `M.on_ready(name, cb)` registered before settlement fires `(true, nil)` on success / `(false, err)` on setup failure; registered after settlement fires immediately with the stored outcome.
- [X] `M.ensure_ready(name)` forces `prepare` then `setup` to run and complete and returns `(ok, err)`.
- [X] `event` is driven in tests via `vim.api.nvim_exec_autocmds` (or equivalent), asserting the full prepare→setup→ready transition.

## Implementation notes (decisions confirmed with user, 2026-08-19)

- **`is_ready` added to the public API** — the spec/ADR export lists predate it
  (the DoD references it). `M.is_ready(name)` → `true`/`false`/`nil`, mirror of
  `is_prepared`; tested.
- **`event` entry shape** — an entry is a plain event name (e.g.
  `"CmdlineEnter"`) or a 2-element `{ event, pattern }` table (e.g.
  `{ "User", "BlinkReady" }`) for `User`-pattern events. One `once` autocmd
  per entry; the cycle is idempotent on the gate's state, so once-across-any
  holds even with multiple entries. This makes the lazy path testable with a
  deterministic, isolated event (nvim rejects arbitrary event names).
- **Context to `prepare` and `setup`** — both receive `{ name, path, spec }`;
  `path` is sourced via `vim.pack.get` (stubbed in tests) and degrades to
  `nil` if the plugin is not resolvable on disk. Also closes the ticket-02
  gap where `prepare` was called with no arguments. Tested.
- **`setup` failure convention** — the first `ensure_ready` after a setup
  failure returns `(false, err)`; later calls re-throw the stored error,
  mirroring the prepared-phase convention. Tested.
- **Failed `prepare` settles `on_ready`** with `(false, err)` on either path
  (event or `ensure_ready`) so no waiter is silently lost; `setup` never
  runs. Tested.
- **Test driver** — events are fired via `doautocmd User <pattern>`
  (nvim 0.12.4's `nvim_exec_autocmds` takes `(event, opts)` and validates
  event names; `User` + pattern is the deterministic, isolated trigger).

## Review pass (2026-08-19)

A deep reviewer pass verified all 9 ACs against the implementation and the
test suite: **no blockers** — every AC is implemented and the suite is
green. Seven AC nuances were flagged as not test-pinned; all were closed
with additional tests (33/33 green):

- event success marks the gate ready and settles `on_ready` with `(true, nil)`
- event ↔ `ensure_ready` interleaving (both orders) keeps prepare/setup at
  exactly one invocation total
- multiple `event` entries are once-across-any (fire A then B: setup once)
- setup failure keeps the `on_prepared` success outcome `(true, nil)`
- `on_ready` registered after settlement fires immediately with the stored
  failure outcome (setup-failure and prepare-failure variants)
- the event path awaits an async (thenable) `prepare` before `setup`
  (order: prepare → pwait → setup)
- event-path setup failure follows the first-return/second-throw
  `ensure_ready` convention