# refer-projectile.nvim

> Implementation context document — intended as authoritative reference for any agent or developer implementing or extending this plugin.

---

## Overview

`refer-projectile` is a self-contained Neovim plugin that provides project-switching functionality inspired by Emacs Projectile and the custom `tmux-picker` / `nv` shell scripts. It lives as a sibling plugin alongside `refer.nvim`, `micro.nvim`, `cling.nvim`, etc. under:

```
~/.config/nvim/lua/custom/refer-projectile.nvim/
```

**Core responsibilities:**
1. **Project picker** — list tmux sessions as "projects" and allow the user to switch to one via `refer.nvim` picker UI
2. **Tmux session management** — switch to an existing session or create a new one
3. **Open project in Neovim** — delegate to the vendored `nv` helper script which handles direnv + tmux session naming
4. **Export vendored scripts** — copy `scripts/nv` and `scripts/tmux-picker` to `~/.local/bin` (or user-specified path) with `+x` permissions so they are usable outside Neovim
5. **ANSI-coloured tmux preview** — while navigating the picker, display the live output of the highlighted session's pane using `tmux capture-pane -p -e -t <session>` rendered in a scratch buffer via `vim.api.nvim_open_term()`

**Design philosophy for prototype:** simple over robust; prioritise exposing the flows end-to-end, not handling every edge case.

---

## Directory Layout

```
refer-projectile.nvim/
├── doc/
│   └── refer-projectile.md        ← this file
├── lua/
│   └── refer_projectile/
│       ├── init.lua               ← public API: pick_project, open_project, export_scripts
│       ├── tmux.lua               ← tmux helpers: list, switch, create, capture_pane
│       └── preview.lua            ← ANSI preview: nvim_open_term scratch buffer
├── plugin/
│   └── refer_projectile.lua       ← plugin bootstrap + :Refer Projectile subcommands
└── scripts/
    ├── nv                         ← vendored nv launcher
    └── tmux-picker                ← vendored tmux-picker
```

The plugin is activated by a loader spec at:
```
~/.config/nvim/lua/plugins/18_refer-projectile.lua
```

---

## User Commands

The plugin integrates into `:Refer` via `refer.add_command(...)` using a two-level subcommand path. The top-level namespace is `Projectile`.

| Command | Description |
|---|---|
| `:Refer Projectile Switch` | Open the project picker; on selection switch tmux client to that session |
| `:Refer Projectile Open` | Prompt for a project path, then delegate to the vendored `nv` helper |
| `:Refer Projectile Export` | Copy vendored scripts to `~/.local/bin` and chmod +x |

**Command naming convention:** `Refer Projectile` (space-separated, not `ReferProjectile`). This follows the natural subcommand dispatch pattern already in `refer.nvim`.

---

## refer.nvim Integration

### Key files
| File | Purpose |
|---|---|
| `lua/refer/init.lua` | Public API module — `setup`, `pick`, `pick_async`, `select`, `add_command`, `get_opts` |
| `lua/refer/picker.lua` | Picker lifecycle — construction, item normalisation, keymap binding, selection callbacks |
| `lua/refer/commands.lua` | Subcommand dispatch (`dispatch`, `complete`) — pattern to clone for `:Refer Projectile` |
| `lua/refer/preview.lua` | File-oriented preview — **not reused** by refer-projectile (tmux preview is custom) |

### Minimal picker flow
```lua
local refer = require("refer")

refer.pick(
  items,           -- string[] or { text: string, data: table }[]
  on_select,       -- fun(selection: string, data: table|nil)
  opts             -- ReferOptions overrides
)
```

- Items can be plain strings or structured `{ text = "...", data = {...} }` tables.
- `data` is passed back verbatim to `on_select`; use it to attach the raw session name.
- Picker supports `on_change` in opts for async/live query updates — used here to trigger preview refresh as the cursor moves.
- Only **one active picker** exists at a time (singleton `_active_picker`). `Picker.new()` automatically closes any existing picker.
- `WinLeave` cancels the picker — be aware when showing a floating preview window alongside.

### Custom keymap / action override
To override `<CR>` behaviour (e.g. calling `switch-client` instead of the default `select_input`):
```lua
opts.keymaps = {
  ["<CR>"] = function(selection, builtin)
    -- selection is the display text
    -- builtin.actions.select_entry() / builtin.actions.close()
    builtin.actions.select_entry()
  end,
}
```

### on_change hook for live preview
```lua
opts.on_change = function(query, callback)
  -- called on every keystroke; callback must receive a table of items
  callback(filtered_items)
end
```
This is the hook used to refresh preview content when the highlighted item changes — though for tmux preview the better approach is to hook into cursor movement via the picker's keymap overrides (`next_item`, `prev_item`) rather than `on_change`.

### Adding subcommands to :Refer
```lua
local refer = require("refer")

-- Simple command
refer.add_command("MyCmd", function(opts) ... end)

-- Nested subcommand path
refer.add_command({ "Projectile", "Switch" }, function(opts) ... end)
refer.add_command({ "Projectile", "Open" },   function(opts) ... end)
refer.add_command({ "Projectile", "Export" }, function(opts) ... end)
```
The dispatch and completion logic in `refer.commands` traverses `refer._registry` as a nested table — each segment in the path becomes a key. The final key must be a function.

### Dispatch pattern (clone for :Refer Projectile if needed)
`refer.commands.dispatch(path_table, opts)` walks the registry and calls the leaf function. `refer.commands.complete(arglead, cmdline, cursorpos)` provides tab-completion. Both are already wired to `:Refer`; registering via `add_command` is sufficient — no need to create a separate `:ReferProjectile` command.

---

## Tmux Session Source (`lua/refer_projectile/tmux.lua`)

### list_sessions
```lua
--- Returns a list of tmux session names, empty table if tmux not running.
--- Uses: tmux list-sessions -F '#S'
function M.list_sessions() -> string[]
```
Implementation notes:
- Use `vim.system({"tmux","list-sessions","-F","#S"}, {text=true}):wait()` (synchronous — acceptable for prototype since the list is small).
- Split stdout on `"\n"`, filter empty strings.
- If return code is non-zero (no tmux server), return `{}`.

### switch_session
```lua
--- Switches the tmux client to the named session (async).
function M.switch_session(session_name: string)
```
- Uses `vim.system({"tmux","switch-client","-t", session_name}, nil, cb)`.
- On error, `vim.notify` at ERROR level.
- Reference: `micro.nvim/lua/micro/project.lua` does exactly this.

### create_session
```lua
--- Creates a new detached tmux session with the given name (sync).
function M.create_session(session_name: string) -> boolean (success)
```
- Uses `tmux new-session -d -s <name>`.
- Returns true on code 0.

### capture_pane
```lua
--- Captures ANSI-coloured output from the first pane of session (async).
--- Uses: tmux capture-pane -p -e -t <session>:0.0
--- Calls callback(lines: string) with raw ANSI escape sequences.
function M.capture_pane(session_name: string, callback: fun(output: string))
```
- Command: `{"tmux", "capture-pane", "-p", "-e", "-t", session_name .. ":0.0"}`.
- `-p` = print to stdout; `-e` = include escape sequences (ANSI colour).
- `TMUX` env var must be unset or blank when calling from inside Neovim to avoid "no current client" errors — pass `env = { TMUX = "" }` to `vim.system`.
- Callback receives the raw stdout string; passes it to `preview.render(bufnr, output)`.

---

## Preview Module (`lua/refer_projectile/preview.lua`)

### Design

The built-in `refer.preview` is file-oriented and does not apply here. Instead, `refer-projectile` maintains its own scratch preview buffer that uses a **terminal channel** to interpret ANSI escape sequences from `tmux capture-pane -p -e`.

```
tmux capture-pane -p -e -t <session>:0.0
        │
        │ raw ANSI text (stdout)
        ▼
vim.api.nvim_open_term(bufnr, {})   ← returns channel_id
        │
vim.api.chan_send(channel_id, output)
        │
        ▼
preview window shows coloured tmux pane snapshot
```

### API
```lua
--- Returns (or creates) the shared scratch terminal buffer for previews.
function M.get_or_create_buf() -> bufnr: number, channel_id: number

--- Renders raw ANSI output into the preview buffer.
--- Replaces any previous content.
function M.render(output: string)

--- Clears the preview buffer state (called on picker close).
function M.cleanup()
```

### Implementation notes
- `vim.api.nvim_open_term(bufnr, {})` must be called while the buffer is **not** displayed in any window, otherwise Neovim may error. Create the buffer first with `nvim_create_buf(false, true)`, then open the terminal channel, then set the buffer in the preview window.
- `chan_send` is the right function to push data into the terminal channel — do **not** use `nvim_buf_set_lines` on a terminal buffer.
- The terminal buffer is `buftype=terminal`; do not set `buftype=nofile` after calling `nvim_open_term`.
- Between renders, the terminal channel cannot be "cleared" — create a fresh buffer+channel each time, or accept that old content remains until the new `chan_send` overwrites it. For the prototype, recreating the buffer per-preview is acceptable.
- The preview window itself is managed by `refer.nvim`'s picker (it opens a split when `preview.enabled = true` in opts). The refer picker calls `preview.show(opts)` which expects a `filename`. To bypass this, pass `preview = { enabled = false }` in `refer.pick` opts and manage the preview window manually — **OR** override the `parser` to return fake file-like data pointing to the scratch terminal buffer (not recommended for prototype).
- **Recommended prototype approach:** disable refer's built-in preview, open a plain float/split manually before calling `refer.pick`, and update its content via `chan_send` from keymap overrides (`next_item`, `prev_item`).

### Keymap wiring for live preview update
```lua
opts.keymaps = {
  ["<C-n>"] = function(selection, builtin)
    builtin.actions.next_item()
    -- after moving, get current selection and refresh preview
    local idx = builtin.picker.selected_index
    local match = builtin.picker.current_matches[idx]
    if match then
      tmux.capture_pane(match.text, function(output)
        vim.schedule(function() preview.render(output) end)
      end)
    end
  end,
  ["<C-p>"] = function(selection, builtin)
    builtin.actions.prev_item()
    -- same pattern
  end,
}
```

---

## Vendored Scripts (`scripts/`)

### `scripts/nv`

**Purpose:** Launch Neovim for a given project directory, wrapping it in a named tmux session and optionally using `direnv exec .` if a `.envrc` is present.

**Behaviour:**
1. Derives session name as `" $(pwd)"` (nf-md-neovim icon + space + current directory).
2. Builds `FINAL_CMD` as either `nvim $@` or `direnv exec . nvim $@` if `direnv` is available and `.envrc` exists.
3. If already inside tmux (`$TMUX` is set): runs `FINAL_CMD` directly in-place.
4. If outside tmux: runs `tmux new-session -A -s "$session_name" "$FINAL_CMD"` (attach-or-create).

**Key constraint:** The session name format ` <cwd>` is intentional — it allows other tooling to recognise sessions created by `nv`. This is a convention, not enforced by the plugin.

**From Neovim:** `M.open_project(path)` in `init.lua` should:
1. Resolve the absolute path.
2. Call `vim.system({"<plugin_scripts_dir>/nv"}, { cwd = path })` — or the exported `~/.local/bin/nv` if already installed.
3. For the prototype, always use the vendored path via `M._scripts_dir()`.

### `scripts/tmux-picker`

**Purpose:** Interactive tmux session picker and creator for use from a terminal (outside Neovim). Uses `gum` if available, falls back to `fzf`, then falls back to plain `read`.

**Notable behaviours:**
- Appends synthetic `[new]` entry to session list.
- `[new]` triggers `_input` to get a name, then creates detached session.
- If inside tmux: `switch-client`; if outside: `attach`.
- Preview (fzf path) uses `tmux capture-pane -p -e -t "$1:0.0"` — same command used by the Neovim preview.

**In the plugin:** this script is vendored for export only. The Neovim-side picker reimplements the core flow in Lua. `tmux-picker` is useful for users who want the same experience from a plain terminal after running `:Refer Projectile Export`.

---

## Script Export Flow (`M.export_scripts`)

```lua
--- Copies all files in the plugin's scripts/ dir to dest_dir, chmod +x each.
--- Default dest_dir: ~/.local/bin
function M.export_scripts(dest_dir: string|nil)
```

**Implementation:**
1. Resolve plugin `scripts/` directory relative to `init.lua`:
   ```lua
   local scripts_dir = vim.fn.fnamemodify(
     debug.getinfo(1, "S").source:sub(2), ":h:h"
   ) .. "/scripts"
   ```
   (`:h` = parent of `init.lua` = `lua/refer_projectile/`, `:h` again = `lua/`, then `.. "/scripts"` is wrong — see correction below.)

   **Corrected path resolution** (from `init.lua` which is at `lua/refer_projectile/init.lua`):
   ```lua
   -- debug.getinfo(1,"S").source:sub(2)  →  .../lua/refer_projectile/init.lua
   -- :h  →  .../lua/refer_projectile
   -- :h  →  .../lua
   -- :h  →  .../<plugin_root>
   local plugin_root = vim.fn.fnamemodify(
     debug.getinfo(1, "S").source:sub(2), ":h:h:h"
   )
   local scripts_dir = plugin_root .. "/scripts"
   ```

2. Iterate files in `scripts_dir` using `vim.uv.fs_scandir` / `vim.uv.fs_scandir_next`.
3. For each file, copy with `vim.uv.fs_copyfile(src, dst)`.
4. Run `vim.system({"chmod", "+x", dst})` after copy.
5. Notify user of success/failure per file.

---

## Plugin Entry Point (`plugin/refer_projectile.lua`)

```lua
if vim.g.loaded_refer_projectile then return end
vim.g.loaded_refer_projectile = true

local rp = require("refer_projectile")
local refer = require("refer")

refer.add_command({ "Projectile", "Switch" }, function(_opts) rp.pick_project() end)
refer.add_command({ "Projectile", "Open" },   function(_opts) rp.open_project() end)
refer.add_command({ "Projectile", "Export" }, function(_opts) rp.export_scripts() end)
```

This is the entire bootstrap. No user commands are created independently — everything goes through `:Refer Projectile <Sub>`.

---

## Loader Spec (`lua/plugins/18_refer-projectile.lua`)

Pattern follows other custom plugins in this config:
```lua
return {
  dir = vim.fn.stdpath("config") .. "/lua/custom/refer-projectile.nvim",
  name = "refer-projectile.nvim",
  dependencies = { "refer.nvim" },
  config = function()
    -- no setup needed for prototype
  end,
  keys = {
    { "<leader>Ps", "<cmd>Refer Projectile Switch<cr>", desc = "Projectile: Switch session" },
    { "<leader>Po", "<cmd>Refer Projectile Open<cr>",   desc = "Projectile: Open project" },
  },
}
```

---

## Prototype Limitations

| Area | Limitation |
|---|---|
| Project source | Only tmux sessions; no filesystem project discovery |
| Session creation | Not yet exposed in picker UI (only `Projectile Switch` switches); must use `Projectile Open` or create session externally |
| Preview | Recreates terminal buffer on each item navigation; may flicker; no debounce |
| `nv` invocation | Always uses vendored script path; does not check if `~/.local/bin/nv` is already installed and preferred |
| Error handling | Minimal; tmux errors shown via `vim.notify` but no recovery logic |
| Config | No `setup()` table; all behaviour is hard-coded |
| `open_project` | Prompts for path with `vim.ui.input`; no path completion or project-root detection |

---

## Implementation Checklist

- [x] Scaffold directories: `lua/refer_projectile/`, `plugin/`, `scripts/`, `doc/`
- [ ] `scripts/nv` — vendored copy, chmod +x
- [ ] `scripts/tmux-picker` — vendored copy, chmod +x
- [ ] `lua/refer_projectile/tmux.lua` — `list_sessions`, `switch_session`, `create_session`, `capture_pane`
- [ ] `lua/refer_projectile/preview.lua` — `get_or_create_buf`, `render`, `cleanup`
- [ ] `lua/refer_projectile/init.lua` — `pick_project`, `open_project`, `export_scripts`, `_scripts_dir`
- [ ] `plugin/refer_projectile.lua` — loaded guard + `refer.add_command` registrations
- [ ] `lua/plugins/18_refer-projectile.lua` — lazy/local plugin spec + keymaps
