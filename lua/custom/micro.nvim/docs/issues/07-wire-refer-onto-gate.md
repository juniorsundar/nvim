# 07 — Wire refer onto the gate (end-to-end bug fix)

**What to build:** The user's refer config entry supplies refer's new prepare hook (from ticket 05), wiring it to the blink.cmp gate (created by ticket 06): `blink_prepare = function() return select(1, require("micro.pack").ensure_prepared("blink.cmp")) end`. End-to-end this fixes the original bug: opening a refer fuzzy picker **before** blink's lazy `CmdlineEnter`/`LspAttach` event no longer prompts a fallback download — refer calls the hook, which forces blink's `prepare` via the gate, then refer retries the native-module load and uses the managed library. refer only prompts when the gate reports blink absent. refer.nvim and blink.cmp remain mutually independent; the dependency lives only in the user's config.

**Blocked by:** 05 — Add a prepare hook to refer.nvim; 06 — Wire blink.cmp into the gate.

**Status:** ready-for-agent

- [ ] The user's refer config entry passes a prepare hook to `refer.setup` that calls `require("micro.pack").ensure_prepared("blink.cmp")` and returns its truthy result.
- [ ] End-to-end: invoking a refer fuzzy picker before blink's lazy event fires does **not** show a fallback-download prompt; instead blink's library is forced via the gate and refer uses it.
- [ ] When blink.cmp is genuinely absent (gate reports absent), refer still falls through to its existing download prompt (the hook returns falsy).
- [ ] No new import of `micro.pack` is introduced inside `refer.nvim` or `blink.cmp` — the only `micro.pack` callers are the user's config files.
- [ ] The stray `libblink_cmp_fuzzy.so` previously downloaded into the refer plugin directory is no longer reached in the common case (refer's native-module load succeeds via the gate).
- [ ] Verified headless in a fresh session (cold state): the first refer fuzzy use before any `CmdlineEnter`/`LspAttach` resolves through the gate without a download prompt.