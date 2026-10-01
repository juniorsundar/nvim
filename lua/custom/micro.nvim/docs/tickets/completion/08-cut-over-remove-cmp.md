# 08: Cut over and remove cmp

**What to build:** Enable `micro.completion` and the convenience keys in the active configuration. Remove nvim-cmp, its source plugins and lock entries, and the cmp/blink capability adapters. Settle the `dynamicRegistration` workaround according to ticket 07's result.

**Blocked by:** 03, 04, 06, 07

**Status:** done

- [x] Active configuration completes natively with the agreed sources and keys
- [x] No cmp plugin config, cmp lock entries or cmp/blink capability merging remain
- [x] `dynamicRegistration` is restored or the workaround is kept with a recorded reason
- [x] The full editor test suite passes on 0.12.5 and nightly after cut-over

Spec: `docs/specs/completion/spec.md`. Evidence: `docs/completion-scope.md`.
