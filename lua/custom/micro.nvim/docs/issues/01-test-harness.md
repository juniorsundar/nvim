# 01 — Test harness for micro.pack

**What to build:** A runnable plenary test setup for the `micro.nvim` module, so that subsequent readiness-gate tickets land with tests that actually execute. Mirror the convention already used by `refer.nvim`: a `minimal_init.lua` that clones plenary and invokes `plenary.busted`, plus a spec directory. No gate logic yet — just one trivial green spec proving the harness runs, plenary loads, and `vim.pack.get` (the only external touchpoint the gate will need) can be stubbed from a test. This is the prefactoring slice: make the change easy, then make the easy change.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A `tests/` directory exists under `micro.nvim` with a `minimal_init.lua` that boots plenary (cloning it if absent, like `refer.nvim/tests/minimal_init.lua`) and runs `plenary.busted`.
- [ ] A trivial spec file runs and passes under the harness (e.g. asserting `require("micro.pack")` loads).
- [ ] A test demonstrates that `vim.pack.get` can be stubbed (e.g. via `luassert.stub`) and the stub is observed by code under test, proving the seam is usable for later gate tests.
- [ ] Running the suite headless exits green.