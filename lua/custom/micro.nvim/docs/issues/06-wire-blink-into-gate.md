# 06 — Wire blink.cmp into the gate (user config only)

**What to build:** The user's blink config entry (which already calls `M.add` for `blink.cmp`) is migrated to declare the gate fields, replacing the hand-rolled `CmdlineEnter`/`LspAttach` autocmd. `event = { "CmdlineEnter", "LspAttach" }`, `prepare` returns `require("blink.cmp").build()` (a `blink.lib.Task`), and `setup` calls `require("blink.cmp").setup { ... }` with the existing options. **blink.cmp itself is not modified** — it is still required and configured the same way; only the user's config glues it to the gate. blink's lazy build+setup behavior is preserved: the native library is still built only on the first `CmdlineEnter`/`LspAttach`, now flowing through the gate. The dependency on `micro.pack` stays in the user's config (which already imports it), never inside `blink.cmp`.

**Blocked by:** 04 — reset and failed-state edge cases (the full gate API must be in place before the user's config can rely on it).

**Status:** ready-for-agent

- [ ] The user's blink config entry declares `event`, `prepare`, and `setup` on the `blink.cmp` spec passed to `M.add`, instead of a hand-rolled autocmd.
- [ ] `prepare` returns `require("blink.cmp").build()` (a `blink.lib.Task` thenable, satisfying the duck-typed contract).
- [ ] `setup` calls `require("blink.cmp").setup { ... }` with the same options as before (keymap, sources, completion, etc.).
- [ ] The old hand-rolled `CmdlineEnter`/`LspAttach` autocmd is removed from the blink config entry.
- [ ] blink's completion still works after the first `CmdlineEnter`/`LspAttach`: the native library is built (or is a no-op if already present for the current commit) and blink is configured, matching prior behavior.
- [ ] `blink.cmp` source files are unchanged (no `micro.pack` import introduced into the plugin).
- [ ] Verified headless: after the event fires, `require("blink.cmp.fuzzy.rust")` succeeds and blink completion behaves as before.