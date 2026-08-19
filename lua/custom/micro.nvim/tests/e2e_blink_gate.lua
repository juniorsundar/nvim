--- Issue 06 end-to-end verification against the REAL installed plugins.
---
--- Run via the Makefile target:  make test-e2e
--- (or: tests/e2e_blink_gate.sh from anywhere)
---
--- Non-destructive by construction:
---   - XDG_CONFIG_HOME points at a SCRATCH dir (created by the .sh wrapper)
---     containing a lockfile with ONLY blink.cmp + blink.lib, so the first
---     vim.pack call syncs exactly those two and no network/bulk install runs.
---   - XDG_DATA_HOME is unset, so the REAL site/pack dir is used read-only.
---     blink.cmp + blink.lib are already installed there and the native lib
--      for the checked-out commit is already built, so build() is a no-op.
---
--- Verifies the issue-06 acceptance criteria:
---   - the blink.cmp spec declares gate fields (gate exists -> is_prepared
---     returns false before the event, never nil)
---   - firing the event drives prepare -> setup through the gate
---   - after the event, require("blink.cmp.fuzzy.rust") succeeds and the gate
---     is ready
local src = debug.getinfo(1, "S").source:sub(2)
local script_dir = src:match("(.*[/\\])"):gsub("[/\\]$", "")
local repo_dir = vim.fn.fnamemodify(script_dir, ":h")
local config_root = vim.fn.fnamemodify(repo_dir, ":h:h:h")

-- Build a scratch lockfile containing only the two plugins under test, so the
-- first vim.pack call does not try to sync the user's full plugin set.
local xdg_config = vim.fn.stdpath "config"
vim.fn.mkdir(xdg_config, "p")
local real_lock = config_root .. "/nvim-pack-lock.json"
local f = io.open(real_lock, "r")
if f then
    local data = vim.json.decode(f:read "*a")
    f:close()
    local subset = { plugins = {} }
    for _, name in ipairs { "blink.cmp", "blink.lib" } do
        if data.plugins[name] then
            subset.plugins[name] = data.plugins[name]
        end
    end
    local out = io.open(xdg_config .. "/nvim-pack-lock.json", "w")
    out:write(vim.json.encode(subset))
    out:close()
end

vim.opt.rtp:prepend(config_root)
vim.opt.rtp:prepend(repo_dir)

-- load the REAL user config entry (this is the code under test)
dofile(config_root .. "/lua/plugins/03_blink.lua")

local pack = require "micro.pack"

local ok_e2e = pcall(function()
    -- 1. gate must exist because the spec declares gate fields. Before the event
    --    it must be declared-but-not-run: is_prepared is false (never nil, which
    --    would mean "no gate").
    local before = pack.is_prepared "blink.cmp"
    if before ~= false then
        error(
            string.format(
                'expected is_prepared("blink.cmp") to be false before the event, got %s (nil would mean no gate)',
                tostring(before)
            ),
            0
        )
    end

    -- 2. fire the lazy event; the gate runs prepare (requires blink.cmp and calls
    --    build(); a no-op if the lib for the current commit exists) then setup
    --    (requires blink.cmp.setup with the user's options).
    vim.cmd "doautocmd CmdlineEnter"

    -- 3. after the event, the native fuzzy module must be loadable and the gate
    --    must be ready.
    local ok_rust, rust = pcall(require, "blink.cmp.fuzzy.rust")
    if not ok_rust or type(rust) ~= "table" then
        error('require("blink.cmp.fuzzy.rust") failed after the event: ' .. tostring(rust), 0)
    end

    local ready = pack.is_ready "blink.cmp"
    if ready ~= true then
        error("expected gate to be ready after CmdlineEnter, got " .. tostring(ready), 0)
    end
end)

if ok_e2e then
    print "E2E-OK is_prepared_before=false ready=true fuzzy_rust_loaded=true"
    vim.cmd "qa!"
else
    print("E2E-FAIL: " .. tostring(e2e_err))
    vim.cmd "cquit"
end
