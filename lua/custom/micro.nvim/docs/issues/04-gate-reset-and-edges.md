# 04 — reset and failed-state edge cases

**What to build:** `M.reset(name)` clears a gate back to its initial un-prepared, un-ready state, drops stored errors, re-creates its `event` autocmd, and fires any pending `on_prepared`/`on_ready` callbacks with `(false, "reset")` so waiters are not silently lost. After a reset, a subsequent `event` fire re-triggers the full prepare→setup→ready cycle. The failed state is fully edge-cased: `ensure_prepared` on a failed gate re-throws the stored error and does not re-run `prepare`; the absent-vs-failed distinction (from ticket 02) is reinforced here for the reset interaction.

**Blocked by:** 03 — Ready phase: event-triggered setup.

**Status:** done

- [X] `M.reset(name)` on a prepared gate clears the prepared/ready/failed flags and stored error.
- [X] After `reset`, `M.is_prepared(name)` returns `false` and the gate behaves as idle.
- [X] `M.reset(name)` re-creates the `event` autocmd; a subsequent event fire re-runs the full prepare→setup→ready cycle.
- [X] `M.reset(name)` fires any pending `on_prepared`/`on_ready` callbacks with `(false, "reset")` so no waiter hangs.
- [X] `M.reset(name)` on a gate with no `event` is a no-op beyond clearing state (does not error).
- [X] `M.reset(name)` on an absent gate (no such plugin) does not error.
- [X] `M.ensure_prepared(name)` on a failed gate re-throws the stored error and does not re-run `prepare`.
- [X] `M.on_prepared`/`M.on_ready` registered on a failed gate fire immediately with `(false, err)` before any reset.
- [X] After `reset` clears a failed gate, a subsequent `ensure_prepared` runs `prepare` afresh (the failed state is not sticky).