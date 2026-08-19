# Per-plugin readiness gates in micro.pack

micro.pack wraps `vim.pack`, which considers a plugin "done" once its repo
is on disk. Some plugins (e.g. blink.cmp) need heavy post-install work — a
native library build via cargo — before dependent plugins can use them.
We add a per-plugin **readiness gate** keyed by `spec.name`, split into
**prepared** (heavy work done) and **ready** (setup also applied), so a
dependent (refer.nvim) can force `prepared` without prematurely running
`setup` and defeating the owning plugin's lazy `event` strategy.

## Why prepare and ready are separate

`blink.cmp`'s `setup` is deliberately deferred to `CmdlineEnter`/
`LspAttach` to keep startup fast. A dependent (refer.nvim) needs the *native
library* (the `prepared` phase) on first fuzzy use, which can happen before
those events. A single `ready` gate would force the dependent to either wait
for `setup` (breaking blink's laziness) or never get the library. Splitting
them gives the user's config an `ensure_prepared` (forces the build, never
setups) to wire into refer's prepare hook, and blink's own config the
`event → prepare → setup → ready` path.

## Why the dependency lives in the user's config, not the plugins

Neither `refer.nvim` nor `blink.cmp` imports `micro.pack`. refer accepts an
opaque, user-supplied prepare hook (a `ReferOptions` field) that it calls
when the native-module load fails; blink is required and configured exactly
as before. Only the user's config files know about both `micro.pack` and the
plugins: the blink entry declares the gate fields, the refer entry supplies
the hook that calls `ensure_prepared`. This keeps the plugins mutually
independent and upstream-clean, and lets the gate be reused by any plugin
manager, not just `micro.pack`.

## Why not just `M.after(name, fn)`

`M.after` as a pure "fires after `vim.pack.add`" callback is insufficient:
`vim.pack.add` returns when the repo is on disk, before the async cargo
build completes. To be correct it would need a `prepare` hook anyway — at
which point it grows into this design minus the `is_prepared`/`ensure_prepared`
pair that refer's hot path and fallback-before-prompt actually need. We
chose the explicit state machine instead of growing `M.after` into one.

## Decided API

- `M.add{ …, event, prepare, setup }` — presence of these fields creates a
  gate. `event` triggers `prepare → setup` once-across-any. `event` entries
  are plain event names or `{ event, pattern }` tables (for `User` events),
  one `once` autocmd per entry.
- `M.is_prepared(name)`, `M.ensure_prepared(name)`, `M.on_prepared(name, cb)`
  — the `prepared` surface (the user's config wires this into refer's hook).
- `M.is_ready(name)`, `M.ensure_ready(name)`, `M.on_ready(name, cb)` — the
  `ready` surface. `is_ready` mirrors `is_prepared` (`true`/`false`/`nil`).
- `M.reset(name)` — clears the gate, re-creates the `event` autocmd, fires
  pending cbs with `(false, "reset")`. Not auto-invoked on `PackChanged`
  update in v1; updates take effect next session.
- `refer.nvim` gains a `ReferOptions` prepare hook — opaque to refer, supplied
  by the user's config — called before any fallback download.

## Considered, rejected

- **`pack:build()/pack:setup()` sugar on a ctx object** — would force micro
  to model arbitrary plugins' setup signatures. Callers `require` the
  plugin themselves; ctx only carries `{ name, path, spec }`.
- **Hard dependency on `blink.lib.Task`** — couples micro to a sibling
  plugin. `prepare` returns a duck-typed thenable (`:pwait()` + (`:map` or
  `.status`)); `nil`/non-thenable means synchronous success.
- **Auto-reset on `PackChanged` update** — mid-session plugin updates are
  rare and blink has no teardown API. Revisit only if it bites.