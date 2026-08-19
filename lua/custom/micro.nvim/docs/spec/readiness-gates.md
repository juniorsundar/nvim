# Readiness Gates for micro.pack

## Problem Statement

As a user of this Neovim config, I have plugins that depend on other plugins'
heavy post-install work — not just their presence on disk. For example,
`refer.nvim` needs `blink.cmp`'s native fuzzy-matcher library to be *built*
(not merely cloned) before its fuzzy sorter works. `vim.pack` (and the
`micro.pack` wrapper) consider a plugin ready the moment its repository is on
disk. The native library build is an asynchronous `cargo build` that runs
later, gated on a lazy `CmdlineEnter`/`LspAttach` event.

When I invoke a refer fuzzy picker *before* that event has fired and the build
has finished, refer sees blink's native module as missing, assumes blink is
not installed, and prompts me to *download its own separate copy* of the
binary — even though blink.cmp is fully installed and configured. This
downloads a stray `libblink_cmp_fuzzy.so` into the refer plugin directory,
which then gets silently reused, polluting the repo and diverging from the
managed blink installation.

I want dependent plugins to be able to wait on — or force — a plugin's heavy
post-install work without each plugin reinventing its own build-gating and
fallback-download logic.

## Solution

`micro.pack` gains a per-plugin **readiness gate**, keyed by the plugin's
`spec.name`. A plugin declares the heavy work that must finish before it is
usable via optional fields on its `M.add` spec: `prepare` (the heavy work,
e.g. the native library build), `setup` (configuration for use), and `event`
(the Neovim event(s) that trigger prepare→setup, kept lazy).

The gate exposes two distinct phases:

- **prepared** — the heavy work has completed. This is what dependent plugins
  (refer) need.
- **ready** — the plugin is prepared *and* configured via its `setup` step.
  `setup` runs only on the gate's `event`, never as a side effect of forcing
  `prepared`, so a plugin's lazy-loading strategy is preserved.

Dependent plugins get an escape hatch — a user-supplied prepare hook —
that forces the heavy work to run and complete on demand, so the user's
config can make blink's library exist *now* on refer's behalf instead of
refer prompting for a fallback download. This separates "blink is absent"
(prompt for download) from "blink is installed but not yet prepared"
(force prepare, then use it). Crucially, the dependency between a plugin
and `micro.pack` lives **only in the user's config** — neither `refer.nvim`
nor `blink.cmp` imports `micro.pack`.

## User Stories

1. As a config author, I want to declare a plugin's heavy post-install work
   alongside its `M.add` spec, so that `micro.pack` knows what must finish
   before the plugin (and its dependents) is usable.
2. As a config author, I want the heavy work to stay lazy — triggered by an
   event I choose — so that startup stays fast and the plugin isn't
   configured until I actually use it.
3. As a config author, I want existing `M.add` calls with no gate fields to
   keep working unchanged, so that adding readiness support is fully backward
   compatible.
4. As a config author wiring a dependent plugin, I want to cheaply ask
   "is this plugin prepared?" without starting or blocking on any work, so
   that the dependent's hot path (every fuzzy keystroke) stays fast.
5. As a config author wiring a dependent plugin, when the owning plugin is
   not yet prepared, I want to force its heavy work to run and complete now
   via a hook I supply, so that the dependent can use the artifact instead
   of downloading its own fallback copy.
6. As a dependent plugin, forcing `prepared` (via the hook I am given) must
   never run the owner's `setup`, so that I don't prematurely configure the
   owner and break its lazy-loading strategy.
7. As a dependent plugin, I want to distinguish "plugin not installed at all"
   from "plugin installed but prepare failed" through the hook's return, so
   that I only offer a fallback download when the plugin is truly absent.
8. As a config author, I want my `setup` step to run exactly once, after
   `prepare` succeeds, triggered by my declared `event`, so that the plugin
   is configured at most once on first use.
9. As a config author, if `prepare` fails (e.g. no cargo toolchain, build
   error), I want `setup` to never run, so that I don't configure a plugin
   whose artifact is missing.
10. As a config author, I want to observe when a plugin becomes prepared
    without forcing it, so that I can react to completion asynchronously
    (e.g. refresh a UI that was waiting on the library).
11. As a config author, I want to observe when a plugin becomes ready
    (prepared + setup done), so that I can gate features on full
    configuration, not just the artifact.
12. As a config author, when a `prepare` is already in flight, I want a
    second call to force/wait to join the same in-flight work rather than
    start a duplicate, so that I don't run two cargo builds at once.
13. As a config author, I want a `reset` that clears a gate back to its
    initial state and re-arms its `event`, so that I can re-trigger a
    prepare cycle (e.g. after manually changing the plugin) within a session.
14. As a config author, when a gate is reset while callbacks are queued, I
    want those waiters notified with a failure rather than silently lost, so
    that no dependent hangs forever.
15. As a config author, I want the gate's `event` to trigger once across any
    of the listed events (not once per event), so that whichever event fires
    first starts the prepare→setup cycle and the rest become no-ops.
16. As a dependent plugin, I want `prepare` to support both synchronous and
    asynchronous implementations, so that a quick check (returns immediately)
    and a long build (returns a thenable) can both be gated.
17. As a future contributor, I want the readiness model to not hard-depend
    on any one plugin's async library, so that the gate can be reused for
    plugins whose heavy work uses a different async mechanism.
18. As a config author, I want a gate keyed by the plugin's own name, so that
    there is exactly one gate per plugin and dependents address it by the
    name they already use.
19. As a config author, I want `setup` failures to leave the gate `prepared`
    but not `ready`, so that a dependent that only needs the artifact
    (refer) keeps working even if the owner's own configuration errors.
20. As a config author, in v1 I want plugin updates mid-session to *not*
    reset the gate, so that I don't risk a mid-session teardown of a
    configured plugin; updates take effect next session.
21. As the refer.nvim maintainer, I want refer to accept a user-supplied
    prepare hook, so that refer can delegate "make the library exist now" to
    the user's config without refer itself depending on any plugin manager.
22. As a config author, I want to wire refer's prepare hook to the blink.cmp
    gate in my own config, so that refer reuses blink's build instead of
    downloading a parallel binary — and the dependency between refer and
    micro.pack lives only in my config, not inside either plugin.
23. As the blink.cmp config maintainer, I want to express blink's current
    lazy build+setup flow declaratively via the gate fields in my own config,
    so that the hand-rolled `CmdlineEnter`/`LspAttach` autocmd can be removed
    without modifying blink.cmp itself.

## Implementation Decisions

### Modules

- **`micro.pack` (the pack module)** — gains the readiness-gate state
  machine and exports. Existing `M.add`/`M.update`/`M.clean`/`M.get`/
  `M.rollback`/`M.health`/`M.setup` are unchanged in behavior.
- **`micro.pack`'s `M.add`** — extended to accept optional gate fields on a
  spec. Presence of any gate field creates a gate for that plugin; absence
  keeps the spec a plain pack spec (backward compatible).
- **refer.nvim** — gains a new optional `ReferOptions` field: a user-supplied
  prepare hook. refer calls it when the blink native-module load fails and
  before any fallback download; if it returns truthy, refer retries the
  load and skips the prompt. refer remains **decoupled** — it imports nothing
  from `micro.pack`; the hook is opaque to refer.
- **The user's config files** (the blink entry and the refer entry) — these
  are the **only** places that know about both `micro.pack` and the
  individual plugins. The blink entry declares the gate fields on its
  `M.add` spec; the refer entry supplies the prepare hook that calls
  `ensure_prepared`. Neither `blink.cmp` nor `refer.nvim` is modified to
  depend on `micro.pack`.

### Gate identity and registration

- A gate is keyed by the plugin's `spec.name`. One plugin → at most one gate.
- A gate is created lazily when an `M.add` spec carries any of the gate
  fields (`event`, `prepare`, `setup`). Specs without these fields create no
  gate and behave exactly as today.
- No separate `name` alias is introduced; the gate name *is* the pack name.

### Spec extension (backward compatible)

`M.add` accepts these additional optional fields on a spec:

- **`event`** — a string or list of entries; the Neovim event(s) that trigger
  `prepare` → `setup`. An entry is a plain event name (`"CmdlineEnter"`) or a
  2-element `{ event, pattern }` table (e.g. `{ "User", "BlinkReady" }`) for
  `User`-pattern events. One `once` autocmd is installed per entry;
  whichever fires first starts the cycle (once-across-any), the rest no-op.
- **`prepare`** — a function performing the heavy work. Receives a context
  table and may return a thenable (see "Thenable contract") for async work,
  or `nil`/a non-thenable for synchronous success.
- **`setup`** — a function configuring the plugin for use. Receives the same
  context. Runs exactly once, after `prepare` succeeds, on `event`.

The context passed to `prepare`/`setup` is `{ name, path, spec }`:
- `name` — the plugin's `spec.name`
- `path` — the plugin's on-disk directory (sourced via `vim.pack.get`)
- `spec` — the normalized spec table

No `pack:build()`/`pack:setup()` sugar methods are introduced; callers
`require` the plugin themselves. This keeps `micro.pack` decoupled from
arbitrary plugins' setup signatures.

### Exported API

- `M.is_prepared(name)` → `boolean | nil`. Cheap, non-blocking, never starts
  work. Returns `true` if prepared, `false` if failed, `nil` if no gate
  exists for `name` (plugin not installed / not declared). Intended for hot
  paths.
- `M.is_ready(name)` → `boolean | nil`. Cheap, non-blocking. `true` if the
  gate is ready (prepared + setup done), `false` if prepared-but-not-ready or
  pending, `nil` if no gate exists.
- `M.ensure_prepared(name)` → `(ok, err)`. Forces `prepare` to run and
  complete if it hasn't (`:pwait()`ing the thenable if needed). Returns
  `(true, nil)` if prepared, `(false, err)` if failed, and a distinct `err`
  (or `nil` ok) indicating the plugin is absent. **Never runs `setup`.**
  Idempotent: if already prepared, returns immediately; if a prepare is
  in flight, joins the same in-flight thenable rather than starting a
  duplicate.
- `M.on_prepared(name, cb)` → registers `cb(ok, err)` fired when the gate
  becomes prepared (or failed). Pure observer: does not start `prepare`. If
  already settled, fires immediately with the stored outcome.
- `M.on_ready(name, cb)` → registers `cb(ok, err)` fired when the gate
  becomes ready (prepared + setup done, or setup failed). Observer only.
- `M.ensure_ready(name)` → `(ok, err)`. Forces `prepare` then `setup` to run
  and complete. May block. This is the lazy path's synchronous escape hatch
  for callers that need full configuration, not just the artifact.
- `M.reset(name)` → clears the gate to its initial un-prepared, un-ready
  state, drops stored errors, re-creates its `event` autocmd, and fires any
  pending `on_prepared`/`on_ready` callbacks with `(false, "reset")` so
  waiters are not silently lost.

### Thenable contract (duck-typed, no hard dependency)

`prepare` may return an async result. The gate detects a thenable by
duck-typing: a return value that has a `:pwait()` method **and** either a
`:map(cb)` method or a `.status` field is treated as a thenable. `nil` or a
return lacking those traits means synchronous success.

This makes `blink.lib.Task` (which has `:pwait`, `:map`, `.status`) satisfy
the contract for free, without `micro.pack` importing or depending on
`blink.lib`. The contract is documented so plugins using a different async
mechanism can still be gated.

### Gate state machine

A gate is an internal record with four boolean/error flags plus a reference
to the in-flight thenable, the `event` autocmd id, and two callback queues
(prepared and ready). The flags are **independent**:

- `prepared` — the heavy work succeeded.
- `ready` — `setup` succeeded (implies `prepared`).
- `failed` — `prepare` errored (stored alongside `error`).
- A `setup` error leaves `prepared = true` and `ready = false` with its own
  stored error — the phases are independent so a dependent needing only the
  artifact is unaffected by a setup failure.

Legal transitions:

- **idle → running prepare** — triggered by `event` fire (first-wins) or
  `ensure_prepared`.
- **running prepare → prepared** — thenable completes successfully.
- **running prepare → failed** — thenable rejects / `prepare` errors. `setup`
  never runs. `on_prepared` cbs fire `(false, err)`.
- **prepared → running setup** — triggered by `event` only (never by
  `ensure_prepared`).
- **running setup → ready** — `setup` returns without error.
- **running setup → (prepared, not ready)** — `setup` errors; `on_ready` cbs
  fire `(false, err)`; `on_prepared` cbs already fired.
- **any → idle** — `reset`. Pending cbs fire `(false, "reset")`; autocmd
  re-created.

Re-entrancy: while `prepare` is running, `ensure_prepared` joins the
in-flight thenable (`:pwait()`), it does not start a second prepare.
`is_prepared` returns `false` during running (cheap, non-blocking).

### Event semantics

- One `once` autocmd per `event` entry (plain name or `{ event, pattern }`
  for `User` events). Whichever fires first runs `prepare` → `setup` → marks
  ready; the autocmd self-deletes and the cycle is idempotent on the gate's
  state, so any later entry firing is a no-op.
- `setup` is triggered **only** by `event`. `ensure_prepared` never runs
  `setup`. This invariant protects a plugin's lazy strategy (forcing the
  library never forces configuration).
- `reset` re-creates the autocmd so a new cycle can trigger.

### Interaction with existing install/update machinery

- `spec.build` (the existing install/update build field) and the gate's
  `prepare` are **not merged**. `spec.build` runs on `PackChanged`
  install/update (disk state); `prepare` is the per-session readiness work
  (the gate). Both can coexist; they serve different lifecycles.
- In v1, `PackChanged` **update** does **not** reset the gate. Mid-session
  plugin updates are rare and re-tearing-down a configured plugin is risky
  (no teardown API). Updates take effect next session, when the new HEAD is
  re-prepared. This is documented; auto-reset is deferred until it's shown
  to matter.

### Migration of the blink entry in the user's config

`blink.cmp` itself is **not** modified. The user's blink config entry (which
already calls `M.add`) declares the gate fields on the blink spec: `event = {
"CmdlineEnter", "LspAttach" }`, `prepare` returns `require("blink.cmp").build()`
(a `blink.lib.Task`), and `setup` calls `require("blink.cmp").setup { ... }`
with the existing options. The hand-rolled `CmdlineEnter`/`LspAttach` autocmd
in that entry is removed. The dependency on `micro.pack` lives in the user's
config (which already imports it), never in `blink.cmp`.

### Migration of the refer entry in the user's config

`refer.nvim` is **not** made to depend on `micro.pack`. refer's `setup` gains
a new optional `ReferOptions` field: a user-supplied prepare hook (a function
returning truthy on success). refer's blink loader calls the hook when the
native-module load fails and before prompting; on a truthy return it retries
the load and skips the download prompt, falling through to the prompt only
when there is no hook or the hook returns falsy.

The user's refer config entry supplies the hook, wiring it to the gate:
`blink_prepare = function() return select(1, require("micro.pack").ensure_prepared("blink.cmp")) end`.
The dependency between `refer.nvim` and `micro.pack` exists **only** in the
user's config; refer treats the hook as opaque. The stray downloaded binary
already present in the refer plugin directory is no longer reached in the
common case.

## Testing Decisions

### What makes a good test

Tests assert **external behavior** of the public `M.*` exports, not
internal flag names or callback ordering. The gate is driven entirely
through `M.add` (with stubbed gate fields) and the exported query/force/
observe functions. Internal tables and autocmd ids are never asserted on
directly.

### Test seam

A new plenary test suite is added under `micro.nvim/tests/`, mirroring the
convention already used by `refer.nvim` (a `minimal_init.lua` that clones
plenary and invokes `plenary.busted`, plus per-feature spec files).

`vim.pack.get` (the only external touchpoint used to fill the context
`path`) is stubbed to return a fake path, so no real plugin is installed
and no real `cargo build` runs. `prepare`/`setup` are stubbed functions:
synchronous returns for the fast paths, and a small duck-typed thenable
stub (with `:pwait()`, `:map()`, `.status`) for the async paths. Neovim
events (`CmdlineEnter`, etc.) are driven via `vim.api.nvim_exec_autocmds`
or by simulating the event in the test.

### What is tested (through the public exports)

- Adding a spec with gate fields creates a gate; adding one without does not
  (no gate, `is_prepared` returns `nil`).
- `is_prepared` returns `false` before prepare, `true` after synchronous
  prepare, `nil` for an unknown name, `false` after a failed prepare.
- `ensure_prepared` on an idle gate runs prepare and returns `(true, nil)`
  for a sync-success prepare.
- `ensure_prepared` on a gate with an async (thenable) prepare `:pwait`s and
  returns the thenable's outcome.
- `ensure_prepared` does **not** run `setup` (assert setup stub is not
  called).
- `ensure_prepared` is idempotent: a second call returns the stored outcome
  without re-running prepare.
- `ensure_prepared` joins an in-flight thenable rather than starting a
  second prepare (assert prepare stub called once across two concurrent
  calls).
- `ensure_prepared` on a failed prepare returns `(false, err)` and re-throws
  the stored error on subsequent calls.
- `ensure_prepared` on an absent plugin returns the distinct absent result.
- `event` fire triggers prepare → setup → ready; the setup stub is called
  once; a second event fire is a no-op (once-across-any).
- If prepare fails, setup is never called and `on_ready` cbs fire
  `(false, err)`.
- If setup fails, the gate is `prepared` but not `ready`; `on_prepared` cbs
  already fired with `true`; `on_ready` cbs fire `(false, err)`.
- `on_prepared` registered before settlement fires `(true, nil)` on
  success; registered after settlement fires immediately with the stored
  outcome; fires `(false, err)` on failure.
- `on_ready` fires only after prepared + setup.
- `reset` clears flags, re-arms the event (a subsequent event re-triggers
  the cycle), and fires pending cbs with `(false, "reset")`.
- The thenable duck-typing: a return with `:pwait()` + (`:map` or `.status`)
  is awaited; a `nil`/non-thenable return is treated as sync success.

### Prior art

`refer.nvim/tests/` — the existing plenary + `minimal_init.lua` + luassert
(`stub`, `assert.are.same`) convention is followed directly, so the new
suite fits the repo's existing test style and runner.

## Out of Scope

- Auto-resetting a gate on `PackChanged` `update` mid-session (deferred to
  v2; updates take effect next session in v1).
- A `reset_ready` distinct from `reset` (there is one gate, one reset).
- Teardown / un-setup of a configured plugin.
- Modeling `pack:build()` / `pack:setup()` sugar methods on the context.
- Hard-depending on `blink.lib.Task` or any specific async library.
- Changing `vim.pack.add` semantics, the install/update build flow, or
  `spec.build`.
- Removing the existing stray downloaded binary from the refer plugin
  directory (left as a safety net; the common case no longer reaches it).

## Further Notes

- This design is recorded in `docs/adr/0001-readiness-gates.md` (the
  decision) and `CONTEXT.md` (the vocabulary: Gate, Prepared, Ready,
  prepare, setup, event, ensure_prepared, on_prepared, Failed, reset).
- The motivating bug is a lazy-loading/timing race: blink's native library is
  resolved per-git-commit, the build runs only on a lazy event, and
  refer's fuzzy is usable before that event fires — so refer sees a missing
  library and downloads its own copy. The gate's `ensure_prepared` is the
  fix: refer can make the library exist now instead of prompting.
- Once the gate ships, refer's fallback-download prompt becomes a
  last-resort path (plugin truly absent), not the common path.