# 03: Full path coverage

**What to build:** Extend path contexts and the filesystem source to the agreed Linux path rules. Relative paths resolve from the effective window working directory; the source enumerates entries and then filters them with native `matchfuzzy()`.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] `../`, `src/`-style relative segments, absolute `/` and `~/` paths are path contexts; `$VAR/` and globs are not
- [ ] Relative paths resolve from the window's cwd, respecting `:lcd` and `:tcd`, not the buffer's directory
- [ ] Directories get a trailing slash; nested segments complete one at a time
- [ ] Dotfiles appear only when the typed segment starts with `.`
- [ ] Names with spaces complete inside quoted paths
- [ ] Unrelated entries are removed, not merely ranked lower

Spec: `docs/specs/completion/spec.md`. Evidence: `docs/completion-scope.md`.
