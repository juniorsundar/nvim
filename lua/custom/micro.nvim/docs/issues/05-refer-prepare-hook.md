# 05 — Add a prepare hook to refer.nvim (plugin stays decoupled)

**What to build:** refer.nvim gains a new optional `ReferOptions` field: a user-supplied prepare hook (a function returning truthy on success). When refer's blink loader fails to `require("blink.cmp.fuzzy.rust")`, it calls the hook before any fallback download; if the hook returns truthy, refer retries the native-module load and skips the download prompt. refer falls through to the existing download prompt only when there is no hook or the hook returns falsy. **refer.nvim imports nothing from `micro.pack`** — the hook is opaque to refer; it could be supplied by any plugin manager or be a plain function. This is a self-contained change to refer.nvim with its own plenary test in refer's existing suite, independent of the gate work.

**Blocked by:** None — can start immediately. (refer's hook is independent of `micro.pack`'s gate; the gate wiring into the hook happens in ticket 07.)

**Status:** ready-for-agent

- [x] `refer.nvim`'s `setup` accepts a new optional `ReferOptions` field for a prepare hook.
- [x] When the blink native-module load fails, refer calls the hook (if supplied) and retries the load on a truthy return, skipping the download prompt.
- [x] When there is no hook or the hook returns falsy, refer falls through to the existing fallback-download prompt (behavior unchanged for users who don't supply a hook).
- [x] `refer.nvim` does **not** `require` or import `micro.pack` anywhere; the hook is treated as an opaque function.
- [x] A plenary test in `refer.nvim/tests/` drives the hook with a stub: a truthy-returning hook causes refer to retry a failing module and not prompt; a falsy/absent hook preserves the existing prompt behavior.
- [x] Existing refer tests still pass (the new option is optional and backward compatible).
