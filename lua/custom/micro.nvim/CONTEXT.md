# micro.pack

The plugin manager wrapper around `vim.pack` for this config. Owns plugin
spec registration, install/update builds, and — distinct from `vim.pack` —
a per-plugin readiness gate so dependent plugins can wait on heavy
post-install work (e.g. a native library build) rather than racing it.

## Language

**Gate**:
A per-plugin readiness handle, keyed by the plugin's `spec.name`.
A plugin has at most one gate, created lazily when its `M.add` spec carries
`prepare`, `setup`, or `event` fields.
_Avoid_: hook, dependency, lifecycle, ready-state

**Prepared**:
The heavy post-install work for a plugin has completed (e.g. the native
`libblink_cmp_fuzzy.so.<commit>` exists). This is the phase dependent
plugins care about — what `refer` needs from `blink.cmp`.
_Avoid_: built, ready

**Ready**:
The plugin has been *prepared* **and** configured via its `setup` step.
`setup` runs only on the gate's `event`, never as a side effect of forcing
`prepared`. This preserves a plugin's lazy-loading strategy.
_Avoid_: configured, initialized

**prepare**:
A function performing the heavy work that produces the *prepared* state.
May return a thenable (duck-typed: has `:pwait()` and `:map(cb)` or a
`.status` field) for async work; `nil` or a non-thenable return means
synchronous success.
_Avoid_: build, compile, install-build

**setup**:
A function configuring the plugin for use. Runs exactly once, after
*prepare* succeeds, triggered by the gate's `event`.
_Avoid_: config, init

**event**:
The Neovim event(s) that trigger `prepare` → `setup` → *ready*, `once`
across any listed event. Lets a plugin stay lazy (e.g. `CmdlineEnter`/
`LspAttach`) instead of configuring at startup.
_Avoid_: trigger, autocmd

**ensure_prepared**:
Synchronously forces `prepare` to run and complete if it hasn't already
(`:pwait()` on the thenable if needed). Never runs `setup`. The escape
hatch that lets a dependent plugin (refer) avoid prompting a fallback
download when the gate owner (blink) is installed but not yet prepared.
_Avoid_: force-build, require-ready

**on_prepared**:
A pure observer: registers a callback fired when the gate becomes
*prepared*. Does not start `prepare`. If already prepared, fires
immediately. On *failed*, fires with `(false, err)` instead of never
firing.
_Avoid_: wait, subscribe, hook

**Failed**:
A gate state entered when `prepare` errors. The error is stored and
re-thrown by `ensure_prepared`; `setup` never runs; `on_prepared` cbs fire
with `(false, err)`. Distinct from *prepared* (the heavy work succeeded)
and from *ready* (setup also succeeded). A dependent that checks
`ensure_prepared` can tell "absent" from "installed but prepare failed".
_Avoid_: broken, errored, dead

**reset**:
Clears a gate back to its initial (un-prepared, un-ready) state and
re-creates its `event` autocmd, so the next event re-runs `prepare`.
Does **not** run as a side effect of `PackChanged` in v1 — updates take
effect next session.
_Avoid_: rearm, reinit