# 04: Automatic trigger tuning

**What to build:** Automatic completion in language contexts waits for a configurable minimum word length (default 2) and debounce (default ~80 ms). Native `'autocomplete'` has no threshold, so routing provides it. Manual completion, server trigger characters and path separators bypass the threshold.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] One word character does not auto-open completion; two do, after the debounce
- [ ] Fast typing within the debounce does not flicker or flood the server
- [ ] A server trigger character (e.g. `.`) opens completion immediately
- [ ] Typing a path separator opens path completion regardless of word length
- [ ] Threshold and debounce are configurable through module options

Spec: `docs/specs/completion/spec.md`. Evidence: `docs/completion-scope.md`.
