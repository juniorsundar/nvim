# Spec: native completion backend (`micro.completion`)

Status: ready-for-agent

Background and verification evidence: `docs/completion-scope.md` (micro.nvim). Glossary: the configuration root's `CONTEXT.md` (**completion source**, **completion candidate**, **path context**, **language context**).

## Problem Statement

My completion setup runs on nvim-cmp and its source plugins, which have their own popup, sorting, matching, and LSP request/acceptance engine. Neovim 0.12 now has native popup rendering, fuzzy matching, documentation popups, LSP completion, snippet expansion and autocomplete built in. Keeping cmp means extra dependencies and a separate UI and behaviour model. It also needs capability workarounds in my LSP setup (cmp/blink capability merging and disabled dynamic registration). Using native completion as-is falls short in two ways:

- Native completion has no filesystem-path source that understands my path rules.
- Native completion has lifecycle bugs. Verified on 0.12.5 and nightly:
  - A late LSP reply reopens the menu after I cancel it.
  - A late reply wipes out an item I explicitly selected.
  - A late reply after switching to path completion corrupts the replacement range, deleting text before the path when I accept.

I want to remove cmp without losing those sources, and without any risk of completion damaging my text.

## Solution

Add a backend-only `micro.completion` module that enhances native completion instead of replacing it. Native Neovim keeps the popup, fuzzy scoring, sorting, documentation, LSP request handling, resolution, acceptance, snippets and additional text edits. The module adds:

- **Routing between contexts.** In a language context, LSP candidates and current-buffer words appear together. In a path context, only filesystem candidates appear.
- **A filesystem completion source** that follows my path rules.
- **A lifecycle guard** at the documented LSP command-factory seam. It drops stale or superseded completion replies before they reach native completion.
- **Automatic and manual triggering** with a word threshold and debounce.

Convenience mappings stay outside the backend, in my micro configuration. Once the combined behaviour passes its checks, cmp, its source plugins, lock entries and capability adapters are removed.

## User Stories

1. As a Neovim user, I want completion to use Neovim's native popup, so that it looks and behaves like built-in completion.
2. As a Neovim user, I want native fuzzy matching and scoring, so that I don't need a third-party matcher.
3. As a Neovim user, I want language-server candidates and words from the current buffer to appear together in language contexts, so that I see identifiers whether or not the server knows them.
4. As a Neovim user, I want buffer words to appear even when the language server returns nothing, so that I still get useful suggestions.
5. As a Neovim user, I want buffer words to come only from the current buffer, so that the menu isn't cluttered with other files' words.
6. As a Neovim user, I want path-shaped text to show only filesystem candidates, so that LSP and buffer words don't pollute path completion.
7. As a Neovim user, I want `./`, `../`, `src/`-style relative paths, absolute paths and `~/` paths treated as path contexts, so that common Linux paths complete.
8. As a Neovim user, I want relative paths resolved from the effective window working directory, respecting `:lcd` and `:tcd`, so that completion matches where commands run.
9. As a Neovim user, I want directories to complete with a trailing slash, so that I can keep descending without typing it.
10. As a Neovim user, I want nested paths to complete segment by segment, so that I can reach deep files.
11. As a Neovim user, I want dotfiles offered when I start a segment with a dot, so that hidden files are reachable without cluttering normal results.
12. As a Neovim user, I want file and directory names containing spaces to complete inside quoted paths, so that real filenames work in strings.
13. As a Neovim user, I want accepting a path to replace only the segment being typed, so that the text before it (for example `open("./`) is never deleted.
14. As a Neovim user, I want path candidates fuzzy-filtered against what I typed, so that unrelated entries are removed rather than just ranked lower.
15. As a Neovim user, I want path completion to ignore environment variables and globs, so that it doesn't silently expand them.
16. As a Neovim user, I want completion to open automatically after two word characters, so that suggestions appear without manual triggering.
17. As a Neovim user, I want a short (~80 ms) debounce before automatic completion, so that fast typing doesn't flicker or flood the server.
18. As a Neovim user, I want the threshold and debounce to be tunable, so that I can adjust them after using them.
19. As a Neovim user, I want server trigger characters (such as `.`) to open completion immediately regardless of the word threshold, so that member access works.
20. As a Neovim user, I want typing a path separator to open path completion regardless of the word threshold, so that path entry stays fluid.
21. As a Neovim user, I want Ctrl-Space to open completion appropriate to the current context, so that I can ask for suggestions at any time.
22. As a Neovim user, I want manual completion to bypass the word threshold, so that I can complete from an empty or one-character prefix.
23. As a Neovim user, I want nothing selected by default, so that Enter never accepts a suggestion I didn't choose.
24. As a Neovim user, I want Enter to accept only an explicitly selected candidate and otherwise insert a newline, so that typing a line break is never hijacked.
25. As a Neovim user, I want Tab and Shift-Tab to move through an open menu, so that I can select with the keys I already use.
26. As a Neovim user, I want Tab and Shift-Tab to jump between snippet placeholders when no menu is open, so that I can fill snippets quickly.
27. As a Neovim user, I want Tab to keep its normal indenting behaviour when there is neither a menu nor an active snippet, so that indentation still works.
28. As a Neovim user, I want menu navigation inside an active snippet to leave the snippet intact, so that I can complete inside a placeholder and continue.
29. As a Neovim user, I want Tab placeholder navigation to work in select mode as well as insert mode, so that snippet placeholders behave consistently.
30. As a Neovim user, I want Ctrl-E to cancel completion, so that I can dismiss the menu.
31. As a Neovim user, I want a completion request still in flight when I press Ctrl-E to be abandoned too, so that a late reply never reopens a menu I dismissed.
32. As a Neovim user, I want my explicit selection to survive late server replies, so that the menu doesn't reset under my cursor.
33. As a Neovim user, I want late language-server replies ignored after the context switches to paths, so that accepting a path cannot corrupt the text before it.
34. As a Neovim user, I want replies dropped after I leave insert mode, change buffer or window, or edit elsewhere in the buffer, so that stale suggestions never appear.
35. As a Neovim user, I want replies to be kept while I keep typing the same word, so that the lifecycle guard doesn't discard useful results.
36. As a Neovim user, I want Ctrl-B and Ctrl-F to scroll the native documentation popup only while the completion popup is open, so that their normal behaviour is kept otherwise.
37. As a Neovim user, I want documentation resolved lazily for the selected candidate, so that the popup shows server documentation without upfront cost.
38. As a Neovim user, I want accepting an LSP snippet to expand it through `vim.snippet`, so that placeholders work natively.
39. As a Neovim user, I want accepting a candidate to apply its additional text edits, such as auto-imports, so that imports appear as with cmp.
40. As a Neovim user, I want additional text edits supplied only when the item is resolved to be applied as well, so that servers that resolve imports lazily still work.
41. As a Neovim user, I want candidates from several language servers attached to one buffer combined natively, so that multi-server setups keep working.
42. As a Neovim user, I want a slow server not to cancel or wipe a faster server's candidates I'm already using, so that multi-server completion stays stable.
43. As a Neovim user, I want completion entries for signature help excluded, so that `micro.signature` remains the only signature-help surface.
44. As a Neovim user, I want no personal snippet collection, so that the only snippets are the ones language servers provide.
45. As a Neovim user, I want refer prompt and results buffers excluded from completion, so that their own Tab and key handling keep working.
46. As a Neovim user, I want buffers with `vim.b.completion = false` and non-file buffers excluded, so that I can switch completion off where it doesn't belong.
47. As a Neovim user, I want completion to work identically on stable 0.12.5 and my installed nightly, so that switching versions doesn't change behaviour.
48. As a Neovim user, I want the guard active from the moment each language server starts, so that every client is protected without restarting.
49. As a Neovim user, I want re-sourcing my configuration not to duplicate hooks or wrappers, so that reloads don't degrade behaviour.
50. As a Neovim user, I want a restarted or re-enabled language server to be guarded too, so that protection survives server restarts.
51. As a Neovim user, I want completion enabled through the micro module defaults and my micro configuration, so that it fits how my other micro modules are turned on.
52. As a Neovim user, I want to be able to disable `micro.completion` and remove the convenience mappings independently, so that the backend and keys can be maintained separately.
53. As a Neovim user, I want cmp, its source plugins, lock entries and the cmp/blink capability adapters removed only after the replacement passes its checks, so that I'm never left without working completion.
54. As a Neovim user, I want dynamic completion registration restored once blink-specific workarounds are gone, provided my servers still work, so that servers use their normal registration.
55. As a Neovim maintainer, I want the backend to delegate LSP request, conversion, resolution and acceptance to native APIs, so that upstream fixes flow through automatically.
56. As a Neovim maintainer, I want the lifecycle guard to drop only `textDocument/completion` replies and pass everything else through untouched, so that other LSP features are unaffected.
57. As a Neovim maintainer, I want the guard to preserve native request bookkeeping when it drops a reply, so that native pending-request tracking never leaks or stalls.
58. As a Neovim maintainer, I want the guard to retire its own tracking on cancellation even if a server never responds, so that misbehaving servers don't cause guard-side leaks.
59. As a Neovim maintainer, I want the guard removed easily once upstream fixes the races, so that the enhancement shrinks over time.
60. As a Neovim maintainer, I want an automated editor-level test suite, so that native-API changes on nightly are caught quickly.

## Implementation Decisions

**Module shape**

- Add one new micro module, `micro.completion`, enabled through the existing micro setup convention: a `completion = { enabled = ... }` entry in the micro defaults, disabled by default, and enabled in my micro configuration.
- Configuration surface (all optional, with defaults): minimum word length (default 2), debounce in milliseconds (default ~80), and the exclusion predicate inputs (filetypes such as `refer_input`/`refer_results`, honouring `vim.b.completion == false` and non-empty `buftype`). No other options until needed.
- The module owns three responsibilities, internal to it: the lifecycle guard, context routing, and the filesystem source. It exposes at most: setup, a public `wrap_cmd(cmd)` (or equivalent) for decorating server commands, `invalidate()` for the convenience layer, and a manual-trigger function that routes before opening completion.
- Convenience mappings live in my micro plugin configuration, not in the backend. They call the backend's manual-trigger and `invalidate()` and otherwise return native keys.

**Native delegation (what the module does not do)**

- No custom popup, renderer, sorter, matcher, request aggregator, resolver, snippet engine or acceptance logic. These stay with `vim.lsp.completion`, `'autocomplete'`, `'complete'`, `'completeopt'` and `vim.snippet`.
- `'completeopt'` keeps `menu,menuone,noselect` and adds native `popup` and `fuzzy`.
- In language contexts, `'complete'` uses current-buffer words plus omnifunc (`.,o`), with the omnifunc set to `vim.lsp.omnifunc`. In path contexts, `'complete'` is set exclusively to the module's filesystem function source. Disabled contexts get no automatic completion.
- No custom LSP timing: the earlier ~300 ms shared deadline and partial-response policy are dropped.

**Lifecycle guard (verified by prototype)**

- Install the guard by decorating each managed server's `cmd` at the documented `vim.lsp.Config.cmd` function-factory seam. It must be applied while the config is resolved, before `vim.lsp.enable()` starts a client; decorating at `LspAttach` or `before_init` is too late. A config decorated after a client has started does not retrofit that client; it takes effect after restart.
- Command decoration is idempotent: decorating an already-decorated command returns the same function, so re-running setup or config resolution never stacks wrappers.
- Command lists are started with `vim.lsp.rpc.start` using the config's `cmd_cwd`, `cmd_env` and `detached`; function commands are called as-is. Every non-completion method and notification passes through unchanged.
- For each outgoing `textDocument/completion` request, record a ticket. On reply, forward the result to native completion only if the ticket is still current. Always forward the native reply-bookkeeping callback, even for dropped replies.
- A ticket is current when all of these still hold (decision distilled from the prototype):

  ```
  current(ticket) =
    not cancelled and not edited_elsewhere and epoch unchanged
    and same buffer, window and document URI
    and insert mode (i / ic)
    and same cursor row
    and line prefix still starts with the request-time prefix,
        extended only by keyword characters
    and suffix after cursor unchanged
    and 'complete', 'omnifunc', 'autocomplete', 'iskeyword' unchanged
    and no explicit selection in the popup
    and transport not closing
  ```

- `changedtick` must **not** be used as an equality gate: native completion temporarily edits and restores the query line, so a fresh reply sees a changed tick. Edits outside the query line are detected with buffer line attachment instead.
- The epoch advances (and in-flight tickets are retired) on: `InsertLeave`, `BufLeave`, `WinLeave`, `CompleteDone`, `LspDetach`, `OptionSet` for `complete`/`omnifunc`/`autocomplete`/`iskeyword`, `CompleteChanged` with a selection, route changes, explicit `invalidate()`, and repeated setup.
- `$/cancelRequest` notifications retire the ticket immediately. Transport exit retires every ticket on that transport. The guard never synthesizes replies and never deletes native request entries; native wire accounting stays vanilla.
- The guard stays module-level state reached through `require`. Clearing it from the module cache while clients are alive is unsupported.

**Context routing**

- Classify the cursor position as a **path context** or a **language context**. Path-shaped tokens are `./`, `../`, a relative segment ending in `/` (such as `src/`), absolute `/` paths and `~/`, including inside quoted strings with spaces. Environment-variable (`$VAR/`) and glob forms are not path contexts.
- Routing changes are applied before the next completion attempt. This includes the character about to be inserted (prospective classification in `InsertCharPre`), so typing a `/` that makes the token path-shaped routes to paths before any native trigger fires.
- When the route changes, invalidate the guard and explicitly disable native LSP completion for the buffer's clients, then re-enable it with server-trigger autotrigger only in language contexts. Inspection showed that calling `vim.lsp.completion.enable()` again with different options does not remove an already-installed autotrigger hook.
- Keep a send-time eligibility check at the transport. A completion request issued while the buffer is excluded or in a path context returns request failure without sending. This covers native trigger timers queued before a route change, as well as manual `get()` calls.
- Re-evaluate routing on `BufEnter`, `FileType`, `InsertEnter`, `LspAttach`, prospective character insertion and manual triggering. Excluded buffers route to "disabled".
- Implement the threshold and debounce in routing: native `'autocomplete'` has no minimum-length option. Manual trigger, server trigger characters and path-separator triggers bypass the word threshold.

**Filesystem source**

- A `'complete'` function source (`F{func}`) returning a start column and items, with `refresh = "always"`.
- Resolve relative paths from the effective window working directory (`getcwd()` for the current window, respecting `:lcd`/`:tcd`), not the buffer's directory. Expand `~` for lookup only.
- The start column is the byte column of the final path segment, so acceptance replaces only that segment (prefix-preserving, including multibyte text before the path).
- Enumerate the directory's entries first, then fuzzy-filter them with native `matchfuzzy()` against the typed segment. `completeopt=fuzzy` alone ranks but does not remove unrelated items, and prefix lookup cannot recover fuzzy matches.
- Directories get a trailing slash. Dotfiles are listed only when the typed segment begins with `.`. Names with spaces are valid inside quoted paths.
- Use native lookup primitives (directory iteration or `getcompletion(..., "file")`), with no new dependency.

**Integration and removal**

- My LSP setup applies command decoration to every server config before enabling it. This config currently consists of `after/lsp` returned tables enabled from `after/ftplugin` `vim.lsp.enable()` calls. A single wildcard-level or shared decoration point is preferred over editing each server file. Capability construction stops merging cmp/blink capabilities.
- `LspAttach` keeps setting the omnifunc. The completion module enables native LSP completion per client/buffer through routing.
- Removal step, gated on passing checks: delete the nvim-cmp plugin configuration and its five lock entries, drop the cmp/blink capability merging, and re-evaluate the disabled `dynamicRegistration` workaround (story 54) after a real-server check.
- Note: the guard intercepts every completion consumer on a managed client. Do not run cmp and the guarded native backend against the same clients during the transition; trial in a native-only profile first.

## Testing Decisions

- **One seam: the editor.** Tests run a headless Neovim, driven by real insert-mode key input, with a scripted LSP server over real stdio JSON-RPC transport. They assert only externally observable behaviour: buffer lines, cursor, popup visibility, popup candidates, selection index, snippet activity, and documentation-popup content/scroll. They do not assert on guard internals, route variables, ticket counters or private native state.
- The scripted server is test-controlled. It can return snippets, completion-time and resolve-time additional edits, documentation and configurable delays. It can deliberately reply after cancellation, return cancellation errors, or never reply, so that the races are reproducible.
- Tests live in micro.nvim's existing Plenary/busted suite, run by its existing `make test` target and minimal init. Prior art: the busted spec suites in the sibling local plugins (refer.nvim, cling.nvim, buffers.nvim, outpost.nvim), and the disposable probe described in `docs/completion-scope.md`. Port its scenarios as behaviour tests; don't copy the throwaway harness.
- The suite must run against both stable 0.12.5 and the installed nightly.
- Required behaviour cases:
  - Language context mixes LSP and buffer candidates.
  - Path context shows only filesystem candidates.
  - Path acceptance preserves the prefix, including quoted spaces and multibyte prefixes.
  - Cwd semantics with `:lcd`.
  - Dotfile visibility, trailing directory slashes and nested segments.
  - Fuzzy filtering removes unrelated entries.
  - Threshold, debounce and trigger bypasses.
  - Snippet and import acceptance, both direct and resolve-time.
  - Documentation scroll.
  - Convenience keys: Enter with and without a selection, Tab precedence across menu, snippet and indent, and select-mode placeholders.
  - Excluded refer-shaped buffers keep their own Tab mapping.
- Required regression cases (from the verified probe):
  - Ctrl-E with an open menu, and with only a request in flight, must not reopen.
  - A late reply must not reset an explicit selection.
  - Switching to paths while LSP is pending must not corrupt the prefix on acceptance.
  - Path contexts send no new LSP completion requests, including server-trigger and queued triggers.
  - Typing more of the same word still accepts the reply.
  - Multi-server: a slow server must not wipe an in-use selection, and the next attempt gets both servers' candidates.
  - Leaving/re-entering, changing buffers/windows, renaming the document and editing other lines drop stale replies.
  - Restart and re-enable guard new clients.
  - Repeated setup doesn't duplicate behaviour.
- One manual/optional smoke check against a real server (lua-language-server) through the guarded startup path. It runs before removing cmp and checks dynamic registration and the real response shapes. It isn't part of the automated seam.
- A good test fails when the user-visible behaviour breaks and survives refactoring of the internals. Avoid sleeps where a polled condition works.

## Out of Scope

- Any custom completion frontend, renderer, kind icons, ghost text or custom sorting.
- Personal snippet collections or snippet sources other than LSP-provided snippets.
- Signature-help completion entries (owned by `micro.signature`).
- Buffer words from other buffers, dictionary, spell, tags, cmdline completion and command-line mode completion.
- Environment-variable and glob path expansion; Windows paths (backslash, `%VAR%`).
- Custom LSP request deadlines, partial-response policies or a replacement request aggregator.
- Rebasing native replacement ranges for reused replies (the guard drops replies instead).
- An upstream Neovim patch, which would be a separate effort; the guard should be easy to remove if one lands.
- Changing popup appearance beyond native options.

## Further Notes

- Evidence: 63 automated scenarios per version passed in the disposable probe (24 guarded compatibility, 23 lifecycle edge and 16 integration scenarios), plus repeated race runs. The probe also established the root cause in native completion: reply callbacks check only the cursor row and insert mode before calling `complete()`.
- Unverified until implementation: full path classification, real filesystem collection under routing, threshold/debounce tuning, the incomplete-result refresh path with the guard (expected to pass via keyword-prefix extension), real third-party servers and dynamic registration, the real refer picker, and pixel-level rendering.
- Conservative expiry can discard otherwise usable replies after edits; accept this rather than rebasing ranges.
- Convenience mappings must return raw key notation, read the documentation window id from `complete_info({"selected"})`, and schedule documentation-window scrolling outside expression evaluation (findings from the probe).
