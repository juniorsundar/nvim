# Native completion enhancement: scope and feasibility

## Status

Scope agreed; the disposable guard prevents the three reproduced races, and **native-only startup/routing integration tests now pass on both versions**. Native acceptance remains intact. Keep cmp until the production backend and full source routing are implemented and verified. No production completion code, mappings, plugin dependencies, or LSP capabilities have been changed.

## Agreed scope

The proposed `micro.completion` enhances native completion rather than replacing its frontend or LSP engine.

- Target Neovim **0.12.5** and the installed **0.13.0-nightly+8d5ebdf**.
- Keep native popup rendering, fuzzy matching/scoring, sorting, documentation, LSP request handling, item resolution, acceptance, snippets and additional edits.
- In language contexts, allow LSP candidates and words from the current buffer together. There is no strict buffer-only fallback policy.
- In path-shaped contexts, offer filesystem candidates exclusively. Interpret relative paths from the effective working directory.
- Support common Linux paths: relative paths including `src/`, `./` and `../`, absolute paths, `~/`, nested directories with trailing slashes, explicitly requested dotfiles, and spaces inside quoted paths.
- Provide automatic and manual completion. Initial tuning preference: ordinary words start at two characters with roughly 80 ms debounce; path/server triggers and manual completion bypass the word threshold. These interactions still need a routing probe; the native engine alone does not establish the chosen threshold.
- Delegate LSP response aggregation and timing to native completion. The earlier guaranteed 300 ms shared deadline and partial-response policy were explicitly dropped.
- Keep convenience mappings outside the backend, in `lua/plugins/15_micro.lua`: Ctrl-Space opens completion; Tab/Shift-Tab navigate an open menu, otherwise snippet placeholders, otherwise retain normal behaviour; Enter accepts an explicit selection, otherwise inserts a newline; Ctrl-E cancels; Ctrl-B/Ctrl-F scroll an open native documentation popup, otherwise retain normal behaviour.
- Keep signature help with `micro.signature`. Support LSP-provided snippets through `vim.snippet`, not a personal snippet collection.
- Preserve exclusions for refer prompts/results and other non-editing buffers; do not hijack their keys or enable automatic completion there.

No custom renderer, fuzzy algorithm, source framework, personal snippet source, environment-variable expansion, glob expansion, or copied/private native LSP conversion helpers are in scope.

## Verified native capabilities

The following observations matched on both tested versions:

| Behaviour | Evidence |
| --- | --- |
| Automatic LSP + current-buffer completion | `complete=.,o` with native `autocomplete` produced both `LspThing` and `LspBuffer`. |
| Manual mixed-source completion | Ctrl-Space mapped to native Ctrl-N used the configured sources, including both LSP and buffer words, without an initial selection. |
| Native documentation resolution | Selecting an LSP candidate sent `completionItem/resolve` and populated the native preview with the fixture documentation. |
| Native acceptance and import edits | Ctrl-Y applied both completion-time and resolve-time `additionalTextEdits`. |
| Native snippet expansion | Accepting an LSP snippet inserted `LspCall(arg)` and activated placeholder navigation. |
| Function-source replacement ranges | A synchronous function source preserved `open("./` when accepting `my folder/`. A separate multibyte-prefix probe verified byte-based start columns. |
| Native filesystem primitives | Built-in Ctrl-X Ctrl-F completed a quoted filename containing spaces. `getcompletion(..., 'file')` collected nested files, explicitly requested dotfiles, directories and home-prefixed paths. |
| Convenience mappings | Enter without selection inserted a newline; Tab without a menu inserted indentation; Tab/Shift-Tab navigated candidates; Enter accepted selection; snippet navigation worked with and without a menu. |
| Native documentation scrolling | A scheduled normal-mode scroll inside the preview window advanced its viewport without changing completion selection or edited text. |
| Leaving insert mode | A response received while still in normal mode did not reopen completion. This does not establish safety after re-entering insert mode. |

### Function sources must supply matching candidates

A function source returning `zzz`, `farBoat`, `foobar`, and `fb` for `fb` was ranked by native fuzzy scoring but still included `zzz`. Do not assume `completeopt=fuzzy` will discard every unrelated item returned by a function source.

Filtering the source list with **native `vim.fn.matchfuzzy()`** before returning it produced `fb`, `farBoat`, and `foobar`, excluding `zzz`. This needs a small source adapter, not a custom matcher.

Likewise, native scoring cannot recover candidates already removed by a server or filesystem prefix lookup. Filesystem collection must enumerate an appropriate candidate set before fuzzy filtering.

### Mapping details learned from the probe

- Query `complete_info({ 'selected' })` to obtain the native preview window identifiers. Requesting only `'preview_winid'` returned an empty dictionary in the probe.
- Expression mappings must not execute `:normal` directly: this raised `E523`. Scheduling the preview scroll worked.
- Return key notation from expression mappings when using their default keycode replacement. Pre-encoding `<Cmd>` broke the initial snippet-navigation fixture; returning the notation restored navigation.

These are probe findings, not installed mappings.

## Confirmed lifecycle blockers

All three behaviours below reproduced on both versions, then reproduced in three additional runs per behaviour per version (18 repeat observations).

### 1. Dismissal does not reliably invalidate an outstanding LSP response

With a completion response delayed by 650 ms, typing `Ls`, dismissing the current buffer menu with Ctrl-E, and waiting without further input allowed the late LSP response to reopen the menu.

A separate probe called the public `client:cancel_request()` for the outstanding completion request. The fixture server recorded receipt of `$/cancelRequest` and subsequently returned the result; the menu still reopened. Cancellation may race with a response, so sending cancellation alone is not a demonstrated lifecycle guard.

### 2. A late response can clear an explicit buffer selection

While the LSP response was pending, selecting `LspBuffer` set the native selection index to `1`. On arrival of the response, the index became `-1`, even though the selected text remained in the buffer. Consequently an explicit-selection Enter mapping would insert a newline rather than accept the previously selected item.

### 3. A late language response can invalidate a path replacement range

Sequence:

1. Start an LSP request for `Ls`.
2. Before its response arrives, switch the native source list to a synchronous path function source and replace the typed text with `open("./my fo`.
3. The path source produces `my folder/` and `my file.txt` with the correct start column.
4. Let the old LSP response arrive, then accept `my folder/`.

The resulting line was **`my folder/`**, not **`open("./my folder/`**. The visible candidate list still looked correct; its replacement range had changed. This is a text-integrity blocker, not merely a presentation quirk.

Control: when the language response had finished before switching sources, the same path acceptance preserved the prefix.

## Validated lifecycle guard prototype

Question: can a guard reject stale replies before native completion receives them, without replacing its conversion, aggregation or acceptance? **Yes, for the tested cases**, through the documented `config.cmd` transport factory.

The prototype wraps the factory's public `rpc.request` and cancellation notifications, not an existing client's methods or private native completion functions:

- Capture the current buffer, window, document URI, source options, query prefix/suffix and a shared menu generation when sending a completion request.
- Invalidate the attempt after dismissal, explicit selection, insert/buffer/window departure, client detachment or source-option changes.
- Observe buffer line changes through `nvim_buf_attach`; reject edits outside the query line without copying the entire buffer.
- Permit unchanged query text or keyword-prefix extension with the same suffix. Do not rebase native replacement ranges.
- Suppress stale **completion handlers** before they feed the native multi-client aggregator. Forward fresh replies normally.
- Always forward the transport's native `notify_reply_callback`, retaining native request accounting. Resolution, snippets, import edits and unrelated methods are untouched.
- Retire guard-owned tracking immediately on known invalidation, cancellation, unrelated-line edits and transport exit. Do not synthesize replies, delete native request entries or add a custom deadline.

### Why a changedtick-only check failed

Native candidate collection temporarily edits and restores the query line. A fresh request captured tick `4`; its reply saw tick `8` with identical text and cursor position. Rejecting every tick change removed legitimate LSP candidates and snippets. Comparing the query context while tracking edits elsewhere avoids that false rejection.

### Supplemental checks

On **each version**, checked the original 24 scenarios with the guard plus **23 additional assertion-based scenarios**:

- All three original races were prevented; the path prefix and explicit buffer selection survived.
- Cancellation before any popup exists worked when the convenience key explicitly invalidated the attempt.
- Leaving and re-entering the same insert context discarded the old reply while allowing the native engine's fresh request.
- Buffer/window changes, window closure, document renaming, source switching back, query-suffix changes and edits elsewhere rejected old replies.
- Keyword-prefix extension still accepted native snippets and both completion-time and resolve-time imports.
- Two-client aggregation remained native. A fast reply followed by explicit buffer selection prevented the slow reply from rebuilding the menu; the next attempt still received both servers' candidates.
- Native server-trigger completion, Ctrl-X Ctrl-O, documentation, snippet/menu navigation and import acceptance continued working.
- Command-list and documented function command factories worked. A separate synchronous public-transport fixture checked callback and reply-accounting forwarding; this is not a full in-process-server integration test.
- Acknowledged cancellation, a cancellation-racing result, client detachment and forced transport exit retained correct cleanup.
- With a deliberately non-conforming server that never replied, cancellation retired guard tracking. Native wire accounting still awaited its required reply or transport exit, exactly as vanilla does.

The final runs had **zero harness/assertion errors**. Repeated the three guarded races three times per version: **18 additional successful observations**. A focused review checked retirement, cleanup order and native reply-accounting preservation.

### Integration conditions and remaining limits

- Install the factory wrapper **before clients start**. The integration tests below verify startup and restart/repeated setup. Decorating a config after startup does not retrofit its running client's transport.
- The no-popup Ctrl-E mapping must call the guard's `invalidate()` before returning the native key. There may be no `CompleteDone` event to observe when only a request is outstanding.
- The backend must explicitly invalidate on routing changes or disablement not represented by native option/session events. Ordinary prefix growth should not invalidate every attempt.
- The router must prevent **new** LSP requests in exclusive path contexts, including server autotrigger requests. This guard protects request lifetime; it is not a path detector or source-eligibility policy.
- Apply the wrapper to native-completion-managed clients. Validate integration in a native-only trial profile first: the transport intercepts completion requests from any consumer on that client, including cmp. Other consumers of `textDocument/completion`, real third-party servers, arbitrary additional-edit shapes and production startup ordering have not been validated.
- Conservative expiry can discard otherwise usable results after edits. No latency/performance benchmark or all-server correctness claim is implied.

## Guard integration verification

The native-only disposable profile follows this repository's startup shape: a returned config in `after/lsp/`, activated by `vim.lsp.enable()` in `after/ftplugin/`. It uses the controlled Python server, not the user's actual servers or full plugin configuration.

**16 integration scenarios passed on each version**, with zero harness/assertion errors:

- Command-list and function-factory configs were decorated before transport creation. Recorded order was factory, original `before_init`, original `on_attach`.
- Wildcard settings/root configuration, command environment and command working directory survived. No cmp module loaded in the trial.
- Repeated setup/config registration kept one client, one transport decorator and unchanged hook counts. Setup invalidates pending attempts before replacing its hooks; the guard remains a require-cached singleton.
- Reload during an outstanding request rejected the old reply and allowed the next attempt. Public disable/enable recreated a guarded client; a second file buffer reused the first guarded client.
- The integrated Ctrl-E key invalidated an outstanding request with no popup.
- Switching from pending language completion to exclusive path candidates retained the quoted path prefix on acceptance.
- New path-context server triggers and manual `get()` did not send completion requests. Switching back restored native trigger-character completion and acceptance.
- A controlled prospective `./` route transition prevented LSP completion traffic. Nightly attempted one already-queued trigger, rejected by the transport eligibility gate; stable attempted none. An explicit ineligible send was also rejected on both versions, without creating pending request entries.
- Buffer disablement expired pending replies; re-enabling allowed completion again. A refer-shaped scratch input preserved its buffer-local Tab owner and excluded completion.
- Native documentation resolution, snippets and resolve-time imports still worked after integration.
- A **negative control** decorated the config only after the client started: its unguarded reply still reopened the menu after cancellation. Restarting from the decorated config activated the guard and prevented reopening. This failure is intentional evidence for the startup-order requirement, not an integration pass by itself.

### Wiring findings

1. Wrap each managed server's command while constructing/resolving its config, before `enable()` starts it. `LspAttach` and `before_init` are too late to decorate a transport that already exists.
2. Reuse module state through `require`; repeated setup must invalidate existing attempts and replace its own hook group without layering command wrappers. Arbitrary clearing of the guard's `package.loaded` entry while clients remain alive was not tested or supported.
3. Changing `autotrigger` options on an already-enabled buffer does **not** remove its installed trigger hook in the inspected native implementation. The trial explicitly disables native completion clients when changing routes, then re-enables them with autotrigger in language contexts.
4. Keep a send-time eligibility check as well: a native trigger timer may already be queued when routing changes. Returning transport request failure for an ineligible completion avoids inventing a reply or replacing the native request engine. Other RPC methods remain delegated.

The final regression run also passed the previous **24 guarded + 23 edge scenarios per version**: **63 scenarios per version including integration**. Formatting, Python compilation and whitespace checks passed.

This verifies integration **mechanics**, not the full planned backend. Path start columns/candidates remain controlled; prospective classification covers only the test's `./` prefix. Actual filesystem collection, full path detection, threshold/debounce tuning, user plugin/server startup and pixel-level rendering remain unverified. Prompt checks reproduce refer's scratch/filetype shape and a buffer-local key; they do not run its entire picker.

## Verification method and limits

- Ran clean, headless editor processes, independent of the user's plugin configuration.
- Used an external Python fixture speaking actual Content-Length-framed JSON-RPC through `vim.lsp.start`, with public native completion entry points.
- The fixture tracks document changes, emits UTF-16 completion ranges for the word at the requested position, supplies snippets and additional edits, resolves documentation, and deliberately allows replies after cancellation. It records RPC receipt and response events.
- Ran **24 scenarios per version**, with zero harness errors in the final runs. An assertion script checks both supported observations and the known gaps. Successful harness checks do **not** mean all desired replacement behaviour passed.
- Downloaded the official 0.12.5 Linux x86-64 release and matched its SHA-256 against the release asset metadata: `bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875`.
- Filesystem source start columns and context switches were supplied explicitly. A production path parser, automatic context detector, two-character gate and prompt exclusions have **not** been implemented or verified. The supplemental probe above verifies the guard and controlled multiple-client cases, not production integration.
- No pixel-level/TUI inspection or third-party language-server integration was performed. These observations apply to the two exact builds tested, not every future nightly.

## Disposable artifacts and reproduction

Artifacts are in `/tmp/nvim-completion-probe/`; they are temporary, not repository dependencies:

- `fixture.lua`: editor fixture and convenience mapping probe.
- `server.py`: controlled JSON-RPC server.
- `run.py`: driver using Python's standard library and Neovim remote commands.
- `check.py`: asserts baseline gaps and their prevention in guarded captures.
- `lifecycle_guard.lua`: disposable public transport guard with diagnostic counters.
- `guard_edges.py`: runnable assertions for the 23 additional lifecycle cases.
- `integration_profile.lua`, `profile/after/lsp/integration-probe.lua`, `profile/after/ftplugin/completionprobe.lua`: native-only startup/routing fixture.
- `integration.py`, `integration-v*.json`: 16 integration assertions and captured results per version.
- `results-v0.12.5.json`, `results-v0.13.0-nightly_8d5ebdf.json`: baseline observations.
- `guard-results-*.json`, `guard-edges-*.json`: final guarded observations.
- `race-repeats.json`, `guard-repeats.json`: 18 baseline and 18 guarded race repeats, respectively.

While the temporary artifacts remain available:

```sh
python3 /tmp/nvim-completion-probe/run.py /tmp/nvim-completion-probe/nvim-linux-x86_64/bin/nvim
python3 /tmp/nvim-completion-probe/run.py /run/current-system/sw/bin/nvim
python3 /tmp/nvim-completion-probe/run.py /tmp/nvim-completion-probe/nvim-linux-x86_64/bin/nvim --guard
python3 /tmp/nvim-completion-probe/run.py /run/current-system/sw/bin/nvim --guard
python3 /tmp/nvim-completion-probe/guard_edges.py /tmp/nvim-completion-probe/nvim-linux-x86_64/bin/nvim
python3 /tmp/nvim-completion-probe/guard_edges.py /run/current-system/sw/bin/nvim
python3 /tmp/nvim-completion-probe/integration.py /tmp/nvim-completion-probe/nvim-linux-x86_64/bin/nvim
python3 /tmp/nvim-completion-probe/integration.py /run/current-system/sw/bin/nvim
python3 /tmp/nvim-completion-probe/check.py
```

The assertions distinguish expected native gaps from guarded behaviour. This is a feasibility probe, not the eventual plugin's regression suite.

## Next step

Implement the production backend using the verified startup/guard wiring, then verify full context routing and filesystem candidate collection. Keep the existing completion plugin until that combined behaviour passes its checks. The guard does not require a replacement LSP conversion or acceptance engine, so the proposed micro-module scope remains viable.

## Primary references

- [Official Neovim 0.12.5 release](https://github.com/neovim/neovim/releases/tag/v0.12.5)
- [Release asset metadata](https://api.github.com/repos/neovim/neovim/releases/tags/v0.12.5)
- [0.12.5 native completion options](https://github.com/neovim/neovim/blob/v0.12.5/runtime/doc/options.txt)
- [0.12.5 function completion contract](https://github.com/neovim/neovim/blob/v0.12.5/runtime/doc/insert.txt)
- [0.12.5 native LSP completion implementation](https://github.com/neovim/neovim/blob/v0.12.5/runtime/lua/vim/lsp/completion.lua)
- [0.12.5 public command factory and RPC contracts](https://github.com/neovim/neovim/blob/v0.12.5/runtime/doc/lsp.txt)
- [0.12.5 RPC reply/cancellation handling](https://github.com/neovim/neovim/blob/v0.12.5/runtime/lua/vim/lsp/rpc.lua)
- Installed nightly runtime: `/nix/store/s6nrg8370lywcl7big7vsnnzq2lhvmdv-neovim-unwrapped-8d5ebdf/share/nvim/runtime`.


## Automatic trigger tuning findings

- Native `'autocompletedelay'` is documented in 0.12.5 but has no effect there: with it set to 600 ms the menu
  opens immediately (plain `complete=.`, no module involved). Nightly honours it. `micro.completion` therefore sets
  the delay but the debounce only takes effect on nightly; the minimum word length works on both.
- `micro.completion` owns the window-local switch of `'autocomplete'`: on in a language context only once the
  word before the cursor (including the character being inserted) reaches `min_word_length`, always on in a path
  context. LSP server trigger characters use native autotrigger, which does not depend on `'autocomplete'`.

## Native trial profile (ticket 07)

`micro.completion.setup()` now wraps `vim.lsp.enable` once (`hook_enable`, idempotent). Every
name enabled afterwards has its resolved `cmd` decorated by `decorate()` before the client can
start, so no server file changes. Configs whose executable is missing keep their list `cmd`, so
native still skips them silently. Servers enabled before `setup()` are not retrofitted.

Run the profile with real servers: `cd <project> && nvim -u <repo>/lua/custom/micro.nvim/tests/trial/init.lua`.
It uses `after/lsp` + `after/ftplugin`, no cmp/blink, and the native default capabilities.

Results (lua-language-server 3.19.1, nightly):

- Started through `after/ftplugin` + `after/lsp`, `cmd` is the guard wrapper. Re-running `setup()` or `decorate()` does not stack wrappers.
- Mixed menu (LSP + buffer words), resolved documentation (11 lines), and `<CR>` acceptance work; `string.format`, `math.max` accepted as expected.
- Dynamic registration: with `dynamicRegistration=false` removed, lua-language-server registers `completionProvider` through `client/registerCapability`. Native supports it (`supports_method` true, completion returns items), but the client is not completion-capable at `LspAttach`, so the module now routes and enables native completion on the first routing event after registration. Covered by a spec using a server that registers dynamically.
- 0.12.5 does not advertise `completion.dynamicRegistration` at all, so servers register statically there.
- The snippet path was not exercised against lua-language-server (its default `callSnippet` is off); snippet acceptance is covered by the scripted-server specs.
- `cmd` wrappers pass `cmd_cwd or root_dir` on nightly, as native does; a spec compares the server's actual working directory.
- Not done: the active configuration (cmp, `serve_capabilities.lua`) is unchanged; ticket 08 removes the cmp/blink capability merge and the `dynamicRegistration=false` workaround.
