# Spec: Grep buffer context expansion + preserved file sync

## Goal

Extend the `grep` buffer type in `buffers.nvim` (see `lua/buffers/grep.lua`,
`ftplugin/grep.lua`) so the user can **expand context lines** around any match —
Zed-style — and so that **every shown line (match *and* context) syncs edits
back to its source file** through the existing apply commands.

This is a spec to hand off: it describes behaviour and the internal data model,
not a line-by-line implementation. Build sessions implement against it.

## Background (current behaviour)

The grep buffer today:

- Is created from raw `file:lnum:col:text` grep output. On first load
  `highlight_buffer` strips the `file:lnum:col:` prefix from each line into a
  virtual-text prefix (via an extmark per match) and leaves the bare `text` as
  the editable buffer line.
- Stores per-match metadata in `M.buffer_data[bufnr][extmark_id] = { filename,
  lnum, col, original_text, dir_len, prefix_str }`. One extmark per match.
- Has a header block of comment lines at the top of the buffer documenting
  keymaps.
- Keymaps (`ftplugin/grep.lua`):
  - `<CR>` → jump to the match under cursor (`nav_to_match`).
  - `<C-c><C-c>` → apply edits direct (`apply_edits "direct"`).
  - `<C-c><C-s>` → apply edits as conflict markers (`apply_edits "conflict"`).
  - `<C-c><C-r>` → refresh content from disk (`refresh_content`).
  - `q` → kill buffer.
- `apply_edits` collects, per file, the lines whose buffer text differs from
  `meta.original_text`, sorts by lnum descending, and does a read-modify-write
  of the whole file (`vim.fn.readfile` / `vim.fn.writefile`), replacing each
  edited lnum in place.
- `refresh_content` re-reads each touched file and overwrites buffer lines with
  the on-disk text for each match's lnum.

## New behaviour

### Expand context (`Tab`)

Pressing `Tab` on a match line (or any of that match's already-expanded
context lines) **expands the context window symmetrically by `N` lines** on each
side of the match, where `N` defaults to **3**.

- Repeated presses of `Tab` grow the window by another `N` each side each time.
- The growth is relative to the **match line**, not the current edge: press 1
  → lines `[match-N, match+N]`; press 2 → `[match-2N, match+2N]`; etc.
- New context lines are inserted into the buffer **above** the topmost and
  **below** the bottommost currently-shown line of that match's block. The
  match line itself never moves relative to its block; the block grows around
  it.
- Each expanded line is **real editable buffer text** taken from the source
  file at that lnum. It is **not** virtual text.
- Each expanded line has **no `file:lnum:col` prefix and no per-line virtual
  text**. Its source `filename` and `lnum` are tracked in metadata only.

#### Block header

A single **block header** is shown once per expanded block, as a virtual-text
line (or a dedicated non-editable row) immediately above the topmost context
line of the block. The header displays **only the filename** (e.g.
`lua/buffers/grep.lua`), styled the same as the existing match-line file
virtual text (`GrepFile` / `GrepFileBase` highlight groups). It does **not**
show line numbers; the covered range is implied by position.

- The header appears as soon as the block has any context lines; it is removed
  when the block is collapsed back to the bare match line.
- If the match's file changes (it never does in practice — each match has a
  fixed filename), the header reflects the match's filename.

#### Boundary handling

When the match is within `N` lines of the top or bottom of the source file,
**clamp to file bounds**: expand only the lines that actually exist on the
shorter side. No error, no padding, no placeholder rows. The window may be
asymmetric when clamped.

### Collapse context (`Shift-Tab`)

Pressing `Shift-Tab` on a match line or any of that match's context lines
**removes all context lines for that match**, collapsing the block back to the
bare match line (match line + its `file:lnum:col` prefix only). The block
header is removed. Any unsaved edits in those context lines are discarded
(they were not applied to disk; collapsing is a buffer-only view change).

### Overlap and dedup

Two matches in the same file may have context windows that cover the **same
source line**. When expanding:

- If a source line is **already shown** in the buffer (as another match's
  match line, or as another match's already-expanded context line), it is
  **not inserted again**. The expansion skips it (dedup). The line keeps its
  existing buffer row and existing metadata.
- A context line therefore maps to exactly one buffer row. Its metadata
  records its own `filename` and `lnum`; it is *associated with* the match
  whose expansion produced it, but on dedup it simply is not added a second
  time.
- Net effect: a source line appears at most once in the buffer, regardless of
  how many matches' windows cover it.

### `<CR>` on context lines

`<CR>` jumps to the file:lnum of **whatever shown line the cursor is on** —
match *or* context. On a context line it jumps to that context line's own
source `filename:lnum` (not the anchor match). Behaviour otherwise matches the
existing `nav_to_match`: `:edit` the file, set cursor to `{lnum, col-1}`,
`normal! zz`.

### Visuals

Expanded context lines get **no special highlight** — they render as normal
buffer text. The match line continues to stand out via its `file:lnum:col`
inline virtual-text prefix; context lines have no such prefix. No dimming,
gutter mark, or separate highlight group is added. (A later, separate effort
can theme this; out of scope here.)

## Edits and sync (apply)

### What syncs

**Every shown line** — match line and every expanded context line — is
editable and syncs back to its source file on apply. Apply considers a line
changed when its current buffer text differs from its recorded original text.

### Edit scope

**In-place line edits only.** Editing the *text* of an existing shown line is
synced. **Inserting or deleting whole lines in the grep buffer is out of
scope** and unsupported: line counts in the grep buffer and the source file
must stay 1:1 per shown line, so each shown line maps trivially to a fixed
source `lnum`. (This keeps lnum bookkeeping trivial and avoids shift
propagation.)

### Sync trigger (manual, existing keys)

Sync stays **manual**, via the existing apply commands:

- `<C-c><C-c>` — direct: replace the source line with the buffer line.
- `<C-c><C-s>` — conflict markers: wrap the on-disk line and the buffer line
  in `<<<<<<< LOCAL` / `=======` / `>>>>>>> REMOTE`.

Both commands now additionally pick up **context lines** (not just match
lines). The implementation iterates all shown lines (match + context), compares
each to its recorded original text, and batches per file as today.

No auto-sync, no background sync, no new sync key.

### Conflict resolution on dedup

Because of dedup, a source line appears at most once in the buffer, so under
normal use there is at most one edit per source line. However, if a source
line somehow appears twice with **divergent edits** (a future edge case, e.g.
if dedup is ever relaxed), apply resolves it as:

- **First (topmost) copy wins.** Apply that copy's text to the source lnum.
- **Warn** the user about the conflict (which file, which lnum, that a
  divergent duplicate was skipped).
- Skip all lower copies of the same source lnum.

### File rewrite

Apply continues to **read-modify-write the whole file**: `vim.fn.readfile`
the file into a Lua table, replace each edited lnum in place, then
`vim.fn.writefile`. Same approach as the existing `apply_edits`. No change to
open-buffer handling: if the file is open in another Neovim buffer with
unsaved changes, that buffer is not consulted and may be overwritten on its
next save — acceptable, matches current behaviour, explicitly in scope to
keep simple.

> Note for implementer: the existing `apply_edits` already does exactly this.
> The only change is that the set of lines it iterates now includes context
> lines.

## Refresh from disk (`<C-c><C-r>`)

The existing refresh command is extended to **re-sync both match lines and
their expanded context lines** from disk:

- For each shown line (match + context), re-read its source file and overwrite
  the buffer line with the current on-disk text at that lnum.
- The current **expansion is preserved** (the same set of source lnums stays
  expanded); only the text is updated.
- Edits made in the buffer to context lines are **overwritten by disk** on
  refresh, exactly as match-line edits are today.
- Update each line's recorded `original_text` to the freshly-read text so it
  no longer reads as "changed".
- Re-render virtual text / headers as needed.

## Internal data model

The spec describes the model the implementation should follow so apply, nav,
dedup, and header rendering all have a consistent source of truth.

### Per-match extmark + context list

Keep the existing **one extmark per match** model (`M.buffer_data[bufnr]`
keyed by extmark id). Extend each match's `meta` with a **context list**:

```lua
meta = {
  -- existing fields
  filename, lnum, col, original_text, dir_len, prefix_str,

  -- new
  context = {
    -- ordered by source lnum; the match line itself is NOT in this list,
    -- it stays the anchor represented by the extmark's row
    { lnum = 10, original_text = "...", buffer_row = 7 },
    { lnum = 11, original_text = "...", buffer_row = 8 },
    ...
  },
  -- the current expanded window, in source-line offset from the match lnum:
  expand_up = 0,   -- number of source lines shown above the match
  expand_down = 0,  -- number of source lines shown below the match
}
```

- The **match extmark anchors the block**. Its row is the match line.
- Context lines are **rows offset from the match row**. The implementation
  inserts/removes buffer rows above and below the match row as the window
  grows/shrinks, and re-stamps affected extmarks/rows so other matches'
  anchors stay valid.
- Each context entry records its `lnum` (source line), `original_text`
  (as read from disk at expansion time, used for change detection on apply),
  and `buffer_row` (current buffer row, kept in sync as rows shift).
- **Dedup** is resolved at expansion time by checking, across all matches'
  current shown lnums (match lnums + all context lnums), whether the
  candidate source lnum is already shown; if so, skip inserting it.

### Finding the line under cursor

`<CR>` and apply both need "which shown line is at buffer row R?": scan each
match's block — if `R == match_row`, it's the match; else look in
`meta.context` for `buffer_row == R`. A small reverse index
(`row_to_meta[bufnr][row] = {match_id, is_match|context_idx}`) may be kept to
avoid the scan; the spec leaves that as an implementation detail.

## Keymap summary (`ftplugin/grep.lua`)

| Key           | Action                                   | New? |
|---------------|------------------------------------------|------|
| `Tab`         | Expand context +3 each side (repeatable) | new  |
| `Shift-Tab`   | Collapse context for match under cursor  | new  |
| `<CR>`        | Jump to file:lnum under cursor           | extended (context too) |
| `<C-c><C-c>`  | Apply edits direct                        | extended (context too) |
| `<C-c><C-s>`  | Apply edits as conflict markers           | extended (context too) |
| `<C-c><C-r>`  | Refresh from disk (matches + context)    | extended |
| `q`           | Kill buffer                              | unchanged |

`N` (the expand step) defaults to 3 and is a constant in `lua/buffers/grep.lua`
(the spec does not require a `setup()` config table, but the implementer may
expose one).

## Out of scope

- Inserting/deleting whole lines in the grep buffer (structural edits that
  shift source lnums).
- Auto-sync / background sync / sync-on-type.
- Consulting open Neovim buffers for the same file before writing to disk.
- Visual styling of context lines (dimming, gutter marks, highlight groups).
- Line numbers in the block header (filename only).
- Per-direction expand keys (expand is symmetric, single key).
- Toggle semantics on the expand key (expand and collapse are separate keys).

## Acceptance

The feature is done when, in a `grep` buffer:

1. `Tab` on a match grows a symmetric ±3 context window each press, inserting
   real editable source lines with a single filename block header and no
   per-line prefixes; clamped at file top/bottom.
2. `Shift-Tab` collapses the block back to the bare match line.
3. Editing a context line then `<C-c><C-c>` writes that line back to its
   source file at the right lnum (verified by re-reading the file).
4. `<C-c><C-s>` does the same with conflict markers.
5. Two nearby matches whose context windows overlap a shared source line show
   that line only once; editing it applies once.
6. `<CR>` on a context line jumps to that context line's source file:lnum.
7. `<C-c><C-r>` updates both match and context lines from disk, keeping the
   current expansion.
8. Existing match-only behaviour (jump, apply, refresh, kill) still works
   unchanged when no context is expanded.