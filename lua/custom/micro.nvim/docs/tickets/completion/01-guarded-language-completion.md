# 01: Guarded language-context completion (tracer bullet)

**What to build:** Add the `micro.completion` module, enabled through the micro setup convention (disabled in defaults). In a **language context**, native completion shows LSP **completion candidates** and current-buffer words together, with native popup, fuzzy scoring, documentation, `vim.snippet` expansion and additional text edits. Install the lifecycle guard at the documented `cmd` function-factory seam (applied before a client starts, idempotent). It drops stale or superseded `textDocument/completion` replies before they reach native completion, and always forwards native reply bookkeeping. Bring up micro.nvim's editor-level test seam: Plenary tests in the existing suite drive a headless editor with real keys against a scripted stdio LSP server (delays, snippets, completion- and resolve-time edits, replies after cancellation, cancellation errors, no reply).

Use the ticket currency rule from the spec (distilled from the prototype). Do not gate on `changedtick`: native completion temporarily edits and restores the query line.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Enabling the module via micro setup yields mixed LSP + current-buffer candidates in a language context (`.,o`, `menu,menuone,noselect,popup,fuzzy`)
- [ ] Accepting an LSP snippet expands via `vim.snippet`; completion-time and resolve-time imports are applied; documentation is resolved for the selected candidate
- [ ] A late reply after Ctrl-E with an open menu does not reopen completion
- [ ] A late reply does not reset an explicit selection
- [ ] Replies are dropped after leaving insert mode, changing buffer/window, renaming the document, or editing another line
- [ ] Replies are accepted while the user keeps typing the same word, including incomplete-result refreshes
- [ ] Two servers: a slow reply does not wipe an in-use selection; the next attempt shows both servers' candidates
- [ ] Cancellation without a server reply leaves no guard-side tracking; non-completion methods pass through unchanged
- [ ] Command decoration is idempotent and preserves `cmd_cwd`, `cmd_env` and `detached`
- [ ] Suite passes via `make test` on 0.12.5 and the installed nightly

Spec: `docs/specs/completion/spec.md`. Evidence: `docs/completion-scope.md`.
