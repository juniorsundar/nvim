# 06: Convenience keys

**What to build:** Add the convenience mappings in the micro plugin configuration, separate from the backend. They call the backend's manual trigger and `invalidate()`, and otherwise return native keys. Probe findings: return raw key notation; read the documentation window from `complete_info({"selected"})`; schedule documentation scrolling outside expression evaluation.

**Blocked by:** 02, 05

**Status:** done

- [x] Ctrl-Space opens context-appropriate completion (language mix or exclusive paths) and bypasses the threshold; excluded buffers get nothing
- [x] Enter accepts only an explicitly selected candidate, otherwise inserts a newline
- [x] Tab/Shift-Tab navigate an open menu, otherwise snippet placeholders, otherwise keep normal behaviour, in insert and select modes
- [x] Navigating the menu inside an active snippet keeps the snippet active
- [x] Ctrl-E cancels completion, including an in-flight request with no menu, which then never reopens
- [x] Ctrl-B/Ctrl-F scroll the native documentation popup only while it is open, otherwise keep normal behaviour
- [x] Excluded refer-shaped buffers keep their own key handling

Spec: `docs/specs/completion/spec.md`. Evidence: `docs/completion-scope.md`.

Note: the mappings live in `micro.completion_keys` (`setup()`), kept apart from the backend. They are deliberately
not called from `lua/plugins/15_micro.lua` yet: enabling them beside active cmp would clash. Ticket 08 wires them in.
