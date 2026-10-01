# 07: Native-only trial profile with real servers

**What to build:** Wire my real LSP setup so every server config is decorated by the guard before `vim.lsp.enable()` starts it, from one shared decoration point rather than editing each server file. Capability construction stops merging cmp/blink capabilities. Exercise this in a native-only profile with cmp off; the active setup is unchanged.

**Blocked by:** 01

**Status:** done

- [x] In the trial profile, every client started through the after/lsp + ftplugin flow is guarded from its first request
- [x] Re-sourcing configuration does not duplicate hooks or wrappers; disable/re-enable and restart produce guarded clients; new buffers reuse guarded clients
- [x] Manual smoke check with lua-language-server: mixed completion, docs, snippets and acceptance work through the guard
- [x] Dynamic completion registration is checked with the `dynamicRegistration=false` workaround removed; the result is recorded
- [x] Active configuration and cmp remain untouched

Spec: `docs/specs/completion/spec.md`. Evidence: `docs/completion-scope.md`.
