# 06: Convenience keys

**What to build:** Add the convenience mappings in the micro plugin configuration, separate from the backend. They call the backend's manual trigger and `invalidate()`, and otherwise return native keys. Probe findings: return raw key notation; read the documentation window from `complete_info({"selected"})`; schedule documentation scrolling outside expression evaluation.

**Blocked by:** 02, 05

**Status:** ready-for-agent

- [ ] Ctrl-Space opens context-appropriate completion (language mix or exclusive paths) and bypasses the threshold; excluded buffers get nothing
- [ ] Enter accepts only an explicitly selected candidate, otherwise inserts a newline
- [ ] Tab/Shift-Tab navigate an open menu, otherwise snippet placeholders, otherwise keep normal behaviour, in insert and select modes
- [ ] Navigating the menu inside an active snippet keeps the snippet active
- [ ] Ctrl-E cancels completion, including an in-flight request with no menu, which then never reopens
- [ ] Ctrl-B/Ctrl-F scroll the native documentation popup only while it is open, otherwise keep normal behaviour
- [ ] Excluded refer-shaped buffers keep their own key handling

Spec: `docs/specs/completion/spec.md`. Evidence: `docs/completion-scope.md`.
