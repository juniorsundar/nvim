# 05: Completion exclusions

**What to build:** Routing disables completion in refer prompt/results buffers, buffers with `vim.b.completion = false`, and non-file buffers. Disabling a buffer expires in-flight replies; re-enabling restores completion.

**Blocked by:** 01

**Status:** done

- [x] refer-shaped prompt and results buffers get no automatic completion and keep their own buffer-local Tab mapping
- [x] `vim.b.completion = false` disables completion and drops pending replies; setting it back re-enables completion
- [x] Non-file (`buftype` set) buffers are excluded

Spec: `docs/specs/completion/spec.md`. Evidence: `docs/completion-scope.md`.
