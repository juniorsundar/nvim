# 02: Exclusive path completion for `./` paths

**What to build:** In a **path context** starting with `./`, only filesystem candidates appear, through a `'complete'` function source. Accepting a candidate replaces only the final path segment. Routing classifies the context before the next attempt, including prospectively for the character being inserted. On a route change, routing invalidates the guard and explicitly disables native LSP completion, re-enabling it with server-trigger autotrigger only in language contexts. Re-enabling with different options does not remove an installed autotrigger hook. A send-time eligibility check at the transport refuses new LSP completion requests while in a path context, covering native trigger timers already queued.

**Blocked by:** 01

**Status:** done

- [x] Typing `./` routes to exclusive filesystem candidates; no LSP or buffer words appear
- [x] Accepting `my folder/` after `open("./my fo` yields `open("./my folder/`, including with a multibyte prefix before the path
- [x] Switching from a pending language request to a path context never corrupts the prefix on acceptance
- [x] No new `textDocument/completion` is sent in a path context: server triggers, manual native `get()`, and queued triggers are refused
- [x] Leaving the path context restores native server-trigger completion and acceptance

Spec: `docs/specs/completion/spec.md`. Evidence: `docs/completion-scope.md`.
