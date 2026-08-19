local M = {}

M.config = {}
M._specs = {}
M._build_queue = {}
M._gates = {}

--- Create a readiness gate for a spec that carries gate fields
--- (prepare, setup, or event). The gate starts in the pending state.
---@param name string Plugin name (spec.name)
---@param spec vim.pack.Spec
---@return table gate
local function create_gate(name, spec)
    return {
        name = name,
        spec = spec,
        state = "pending", -- pending | prepared | failed
        err = nil,
        thenable = nil, -- in-flight prepare thenable
        fail_returned = false, -- first ensure_prepared call already returned (false, err)
        ready = false, -- setup succeeded (implies prepared)
        setup_failed = false, -- setup ran and errored
        setup_err = nil,
        setup_returned = false, -- first ensure_ready after setup failure already returned (false, err)
        ready_outcome = nil, -- { ok, err } once the on_ready queue has settled
        on_prepared = {},
        on_ready = {},
        autotids = {}, -- event autocmd ids (re-created on reset)
    }
end

--- Duck-type check from CONTEXT.md: has `:pwait()` and (`:map` or `.status`).
---@param x any
---@return boolean
local function is_thenable(x)
    return type(x) == "table" and type(x.pwait) == "function" and (type(x.map) == "function" or x.status ~= nil)
end

--- Settle a gate into prepared or failed and fire its on_prepared observers.
---@param gate table
---@param ok boolean
---@param err string?
local function settle(gate, ok, err)
    gate.err = ok and nil or err
    gate.state = ok and "prepared" or "failed"
    gate.thenable = nil

    local cbs = gate.on_prepared
    gate.on_prepared = {}
    for _, cb in ipairs(cbs) do
        pcall(cb, ok, ok and nil or err)
    end
end

--- Build the context passed to `prepare`/`setup`: `{ name, path, spec }`.
--- `path` is sourced via `vim.pack.get`; if the plugin is not (yet)
--- resolvable on disk it degrades to nil rather than erroring the gate.
---@param gate table
---@return table ctx
local function build_ctx(gate)
    local ctx = {
        name = gate.name,
        spec = gate.spec,
    }
    local ok, res = pcall(vim.pack.get, { gate.name }, { info = false })
    if ok and type(res) == "table" and res[1] then
        ctx.path = res[1].path
    end
    return ctx
end

--- Force the gate to prepared: run (or join) `prepare` if pending.
--- Never runs `setup`. On a failed gate the first call returns
--- `(false, err)`; later calls re-throw the stored error.
---@param gate table
---@return boolean ok
---@return string? err
local function gate_ensure_prepared(gate)
    if gate.state == "prepared" then
        return true, nil
    end

    if gate.state == "failed" then
        if gate.fail_returned then
            error(gate.err)
        end
        gate.fail_returned = true
        return false, gate.err
    end

    -- pending: run `prepare` exactly once, join an in-flight thenable
    if gate.spec.prepare == nil then
        settle(gate, true, nil)
        return true, nil
    end

    if gate.thenable then
        local ok, err = gate.thenable:pwait()
        settle(gate, ok and true or false, err)
        if not ok then
            gate.fail_returned = true
        end
        return ok and true or false, err
    end

    local ok, res = pcall(gate.spec.prepare, build_ctx(gate))
    if not ok then
        settle(gate, false, res)
        gate.fail_returned = true
        return false, res
    end

    if is_thenable(res) then
        gate.thenable = res
        local t_ok, err = res:pwait()
        settle(gate, t_ok and true or false, err)
        if not t_ok then
            gate.fail_returned = true
        end
        return t_ok and true or false, err
    end

    settle(gate, true, nil) -- nil / non-thenable return is a synchronous success
    return true, nil
end

--- Settle the gate's ready outcome and fire its on_ready observers.
--- Idempotent: the first settlement is final (cleared only by reset).
---@param gate table
---@param ok boolean
---@param err string?
local function settle_ready(gate, ok, err)
    if gate.ready_outcome then
        return
    end
    gate.ready_outcome = { ok = ok, err = err }

    local cbs = gate.on_ready
    gate.on_ready = {}
    for _, cb in ipairs(cbs) do
        pcall(cb, ok, ok and nil or err)
    end
end

--- Run the gate's `setup` exactly once, after prepare succeeded.
--- A missing `setup` settles the gate as ready immediately.
---@param gate table
---@return boolean ok
---@return string? err
local function run_setup(gate)
    if gate.ready or gate.setup_failed then
        if gate.ready then
            return true, nil
        end
        return false, gate.setup_err
    end

    if gate.spec.setup == nil then
        gate.ready = true
        settle_ready(gate, true, nil)
        return true, nil
    end

    local ok, res = pcall(gate.spec.setup, build_ctx(gate))
    if not ok then
        gate.setup_failed = true
        gate.setup_err = res
        settle_ready(gate, false, res)
        return false, res
    end

    gate.ready = true
    settle_ready(gate, true, nil)
    return true, nil
end

--- Drive the gate's full cycle: prepare (force/join) then setup.
--- A failed prepare settles the ready outcome as (false, err) so no
--- on_ready waiter is silently lost; setup never runs.
---@param gate table
---@return boolean ok
---@return string? err
local function run_cycle(gate)
    local ok, err = pcall(gate_ensure_prepared, gate)
    if gate.state ~= "prepared" then
        settle_ready(gate, false, gate.err)
        if ok then
            return false, gate.err
        end
        error(err) -- stored error re-thrown by gate_ensure_prepared
    end
    return run_setup(gate)
end

--- Normalise a spec's `event` field into a list of entries.
--- Each entry is a plain event name (string) or a 2-element
--- `{ event, pattern }` table for User-pattern events.
---@param event any
---@return table[]
local function normalize_event(event)
    if type(event) == "string" then
        return { event }
    end
    if type(event) == "table" then
        return event
    end
    return {}
end

--- Install the gate's event autocmd(s): one `once` autocmd per entry.
--- Whichever fires first runs the prepare → setup cycle; the rest
--- no-op because the cycle is idempotent on the gate's state.
---@param gate table
local function install_event(gate)
    for _, entry in ipairs(normalize_event(gate.spec.event)) do
        local ev, pattern
        if type(entry) == "string" then
            ev = entry
        elseif type(entry) == "table" then
            ev, pattern = entry[1], entry[2]
        end
        if type(ev) == "string" then
            local opts = {
                once = true,
                callback = function()
                    -- the lazy path must never raise into the event loop;
                    -- outcomes are observable through the public API
                    pcall(run_cycle, gate)
                end,
            }
            if pattern ~= nil then
                opts.pattern = pattern
            end
            local ok, id = pcall(vim.api.nvim_create_autocmd, ev, opts)
            if ok then
                table.insert(gate.autotids, id)
            end
        end
    end
end

--- Expand URI shorthand prefixes into full HTTPS URLs.
--- Local filesystem paths (starting with /, ~/, ./) are passed through as-is.
--- Everything else is also passed through as-is (assumed to be a full URI).
---@param src string
---@return string
function M._expand_src(src)
    local prefix, rest = src:match "^([a-z][a-z]?):(.+)$"
    if not prefix then
        return src
    end

    local hosts = {
        gh = "https://github.com/",
        gl = "https://gitlab.com/",
        cb = "https://codeberg.org/",
    }

    local base = hosts[prefix]
    if base then
        return base .. rest
    end

    -- Unknown prefix — pass through as-is
    return src
end

--- Derive the canonical plugin name from a spec.
--- Uses spec.name if set, otherwise extracts the final path component from src.
---@param spec vim.pack.Spec
---@return string
function M._resolve_name(spec)
    if spec.name and spec.name ~= "" then
        return spec.name
    end
    local name = spec.src:gsub("[/\\]+$", ""):match "([^/\\]+)$"
    if not name or name == "" then
        error("micro.pack: cannot derive plugin name from src: " .. spec.src)
    end
    return name
end

--- Normalise a single spec item into a proper vim.pack.Spec table with expanded src.
---@param item string|vim.pack.Spec
---@return vim.pack.Spec
local function normalise_spec(item)
    local spec
    if type(item) == "string" then
        spec = { src = item }
    elseif type(item) == "table" then
        spec = vim.deepcopy(item)
    else
        error("micro.pack.add: spec must be a string or table, got " .. type(item))
    end

    spec.src = M._expand_src(spec.src)
    return spec
end

--- Execute a build command for a plugin.
---@param name string Plugin name
---@param build string|function Build command or function
---@param path string Plugin path on disk
local function run_build(name, build, path)
    if type(build) == "function" then
        vim.notify("micro.pack: running build function for " .. name, vim.log.levels.INFO)
        local ok, err = pcall(build, path)
        if not ok then
            vim.notify("micro.pack: build failed for " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
        end
    elseif type(build) == "string" then
        vim.notify("micro.pack: running build for " .. name .. ": " .. build, vim.log.levels.INFO)
        vim.system({ "sh", "-c", build }, { cwd = path }, function(res)
            if res.code ~= 0 then
                vim.schedule(function()
                    vim.notify(
                        "micro.pack: build failed for " .. name .. " (exit " .. res.code .. ")\n" .. (res.stderr or ""),
                        vim.log.levels.ERROR
                    )
                end)
            else
                vim.schedule(function()
                    vim.notify("micro.pack: build completed for " .. name, vim.log.levels.INFO)
                end)
            end
        end)
    end
end

--- Process queued builds after PackChanged event.
--- Only runs builds for install/update kinds — not delete.
---@param kind string The PackChanged event kind: "install", "update", or "delete"
---@param name string The plugin name from the event
local function process_build_queue(kind, name)
    if kind == "delete" then
        -- Never run builds for deleted plugins
        M._build_queue[name] = nil
        return
    end
    if M._build_queue[name] then
        local spec = M._specs[name]
        if spec and spec.build then
            local plug_info = vim.pack.get({ name }, { info = false })[1]
            if plug_info then
                run_build(name, spec.build, plug_info.path)
            end
        end
        M._build_queue[name] = nil
    end
end

--- Add plugin(s) — installs immediately if missing, loads into session.
--- Accepts a single spec (string or table) OR a list of specs.
--- Returns M for chaining.
---@param specs string|vim.pack.Spec|(string|vim.pack.Spec)[]
---@param opts table? Options passed directly to vim.pack.add()
---@return table M
function M.add(specs, opts)
    local items
    if type(specs) == "string" then
        items = { specs }
    elseif type(specs) == "table" and specs.src then
        items = { specs }
    elseif type(specs) == "table" then
        items = specs
    else
        error("micro.pack.add: specs must be a string, spec table, or list, got " .. type(specs))
    end

    local expanded = {}
    for _, item in ipairs(items) do
        local spec = normalise_spec(item)
        local name = M._resolve_name(spec)
        M._specs[name] = spec
        table.insert(expanded, spec)
        if spec.build then
            M._build_queue[name] = true
        end
        if spec.prepare or spec.setup or spec.event then
            local old = M._gates[name]
            if old then
                for _, id in ipairs(old.autotids) do
                    pcall(vim.api.nvim_del_autocmd, id)
                end
            end
            local gate = create_gate(name, spec)
            install_event(gate)
            M._gates[name] = gate
        end
    end

    vim.pack.add(expanded, opts)
    return M
end

--- Update managed plugins. If names is nil, updates all declared plugins.
---@param names string[]? List of plugin names to update
---@param opts table? Options passed directly to vim.pack.update()
function M.update(names, opts)
    local target = names
    if not target then
        target = vim.tbl_keys(M._specs)
        if #target == 0 then
            vim.notify("micro.pack: no plugins declared", vim.log.levels.WARN)
            return
        end
    end
    vim.pack.update(target, opts)
end

--- Remove plugins from disk that are no longer declared in M._specs.
---@param opts table? { force?: boolean } — force=true skips interactive prompt
function M.clean(opts)
    opts = opts or {}

    local all = vim.pack.get()
    local orphans = {}

    for _, plug in ipairs(all) do
        local name = plug.spec.name
        if name and not M._specs[name] then
            table.insert(orphans, plug)
        end
    end

    if #orphans == 0 then
        vim.notify("micro.pack: nothing to clean", vim.log.levels.INFO)
        return
    end

    local function format_entry(p)
        local status = p.active and " [active]" or ""
        return string.format("%s%s", p.spec.name, status)
    end

    if opts.force then
        local orphan_names = vim.tbl_map(function(p)
            return p.spec.name
        end, orphans)
        vim.pack.del(orphan_names, { force = false })
        vim.notify("micro.pack: cleaned " .. #orphan_names .. " plugin(s)", vim.log.levels.INFO)
        return
    end

    local items = vim.tbl_map(format_entry, orphans)
    table.insert(items, 1, "[All]")

    vim.ui.select(items, {
        prompt = "micro.pack: orphaned plugin(s) found — choose action:",
        kind = "micro.pack.clean",
    }, function(choice, idx)
        if not choice or idx == #items then
            vim.notify("micro.pack: clean cancelled", vim.log.levels.INFO)
            return
        end

        if idx == 1 then
            local orphan_names = vim.tbl_map(function(p)
                return p.spec.name
            end, orphans)
            vim.pack.del(orphan_names, { force = false })
            vim.notify("micro.pack: cleaned " .. #orphan_names .. " plugin(s)", vim.log.levels.INFO)
            return
        end

        local selected_plugin = orphans[idx - 1]
        if selected_plugin then
            vim.pack.del({ selected_plugin.spec.name }, { force = false })
            vim.notify(string.format("micro.pack: cleaned '%s'", selected_plugin.spec.name), vim.log.levels.INFO)
        end
    end)
end

--- Get info about managed plugins. Thin passthrough to vim.pack.get().
---@param names string[]?
---@param opts table?
---@return table[]
function M.get(names, opts)
    return vim.pack.get(names, opts)
end

--- Rollback plugin(s) to the revision recorded in the lockfile.
--- This is useful when an update breaks something and you want to revert.
---@param names string[]? List of plugin names to rollback. Default: all declared plugins.
function M.rollback(names)
    local target = names
    if not target then
        target = vim.tbl_keys(M._specs)
        if #target == 0 then
            vim.notify("micro.pack: no plugins declared", vim.log.levels.WARN)
            return
        end
    end

    vim.notify("micro.pack: rolling back " .. #target .. " plugin(s) to lockfile revisions...", vim.log.levels.INFO)
    vim.pack.update(target, { target = "lockfile", force = false })
end

--- Check health of managed plugins.
--- Validates that all declared plugins exist on disk and reports any issues.
---@return table results A table with { healthy: string[], missing: string[], errors: string[] }
function M.health()
    local results = {
        healthy = {},
        missing = {},
        errors = {},
    }

    local all_on_disk = {}
    for _, plug in ipairs(vim.pack.get()) do
        local pname = plug.spec and plug.spec.name
        if pname then
            all_on_disk[pname] = plug
        end
    end

    for name, spec in pairs(M._specs) do
        local plug = all_on_disk[name]
        if not plug then
            table.insert(results.missing, name)
        else
            if plug.spec.src ~= spec.src then
                table.insert(
                    results.errors,
                    string.format("%s: src mismatch (disk=%s, spec=%s)", name, plug.spec.src, spec.src)
                )
            else
                table.insert(results.healthy, name)
            end
        end
    end

    local lines = { "micro.pack health check:" }
    table.insert(lines, string.format("  ✓ %d plugins healthy", #results.healthy))
    if #results.missing > 0 then
        table.insert(
            lines,
            string.format("  ✗ %d plugins missing: %s", #results.missing, table.concat(results.missing, ", "))
        )
    end
    if #results.errors > 0 then
        table.insert(lines, string.format("  ! %d plugins with errors:", #results.errors))
        for _, err in ipairs(results.errors) do
            table.insert(lines, "    " .. err)
        end
    end
    local has_issues = #results.missing > 0 or #results.errors > 0
    vim.notify(table.concat(lines, "\n"), has_issues and vim.log.levels.WARN or vim.log.levels.INFO)

    return results
end

--- High-level setup hook. Does NOT defer/batch installs — M.add() is
--- always immediate. Use this for future config like on_change hooks.
---@param opts table?
function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend("force", M.config, opts)

    local augroup = vim.api.nvim_create_augroup("MicroPack", { clear = true })
    vim.api.nvim_create_autocmd("PackChanged", {
        group = augroup,
        callback = function(args)
            local data = args.data or {}
            if data.spec and data.spec.name then
                process_build_queue(data.kind or "", data.spec.name)
            end
            if type(M.config.on_change) == "function" then
                M.config.on_change(data)
            end
        end,
    })

    if opts.specs and type(opts.specs) == "table" then
        M.add(opts.specs)
    end
end

--- Force the gate to prepared: run (or join) `prepare` if pending.
--- Never runs `setup`. On a failed gate the first call returns
--- `(false, err)`; later calls re-throw the stored error.
---@param name string Plugin name (spec.name)
---@return boolean ok true prepared, false failed or no gate
---@return string? err nil on success; stored error, or "absent" if no gate exists
function M.ensure_prepared(name)
    local gate = M._gates[name]
    if not gate then
        return false, "micro.pack: no gate for '" .. name .. "' (plugin absent?)"
    end
    return gate_ensure_prepared(gate)
end

--- Force the gate to ready: run (or join) `prepare`, then run `setup`,
--- and complete. The lazy path's synchronous escape hatch for callers
--- that need full configuration, not just the artifact. On a gate whose
--- `setup` failed, the first call returns `(false, err)` and later calls
--- re-throw the stored error (mirroring the prepared-phase convention).
---@param name string Plugin name (spec.name)
---@return boolean ok true ready, false failed or no gate
---@return string? err nil on success; stored error, or "absent" if no gate exists
function M.ensure_ready(name)
    local gate = M._gates[name]
    if not gate then
        return false, "micro.pack: no gate for '" .. name .. "' (plugin absent?)"
    end

    if gate.setup_failed then
        if gate.setup_returned then
            error(gate.setup_err)
        end
        gate.setup_returned = true
        return false, gate.setup_err
    end

    local ok, err = run_cycle(gate)
    if not ok and gate.setup_failed then
        -- this call returns (false, err); the next one re-throws
        gate.setup_returned = true
    end
    return ok, err
end

--- Clear the gate back to its initial un-prepared, un-ready state and drop
--- stored errors, so a subsequent force or event fire runs the cycle afresh.
--- No-op (no error) if no gate exists for `name`.
---@param name string Plugin name (spec.name)
---@return table M
function M.reset(name)
    local gate = M._gates[name]
    if gate then
        gate.state = "pending"
        gate.err = nil
        gate.thenable = nil
        gate.fail_returned = false
        gate.ready = false
        gate.setup_failed = false
        gate.setup_err = nil
        gate.setup_returned = false
        gate.ready_outcome = nil
        -- fire pending waiters with (false, "reset") so none are silently lost
        local p_cbs, r_cbs = gate.on_prepared, gate.on_ready
        gate.on_prepared = {}
        gate.on_ready = {}
        for _, cb in ipairs(p_cbs) do
            pcall(cb, false, "reset")
        end
        for _, cb in ipairs(r_cbs) do
            pcall(cb, false, "reset")
        end

        -- re-create the event autocmd so a new cycle can trigger
        for _, id in ipairs(gate.autotids) do
            pcall(vim.api.nvim_del_autocmd, id)
        end
        gate.autotids = {}
        install_event(gate)
    end
    return M
end

--- Pure observer: fires `cb(ok, err)` when the gate becomes ready
--- (prepared + setup done, or setup failed), or immediately if it is
--- already settled. Never starts `prepare` or `setup`.
---@param name string Plugin name (spec.name)
---@param cb function callback(ok: boolean, err: string?)
function M.on_ready(name, cb)
    local gate = M._gates[name]
    if not gate or type(cb) ~= "function" then
        return
    end
    local outcome = gate.ready_outcome
    if outcome then
        cb(outcome.ok, outcome.ok and nil or outcome.err)
    elseif gate.state == "failed" then
        -- a failed gate can never become ready: notify the waiter now
        cb(false, gate.err)
    else
        table.insert(gate.on_ready, cb)
    end
end

--- Pure observer: fires cb(ok, err) when the gate settles, or immediately
--- if it is already settled. Never starts `prepare`.
---@param name string Plugin name (spec.name)
---@param cb function callback(ok: boolean, err: string?)
function M.on_prepared(name, cb)
    local gate = M._gates[name]
    if not gate or type(cb) ~= "function" then
        return
    end
    if gate.state == "prepared" then
        cb(true, nil)
    elseif gate.state == "failed" then
        cb(false, gate.err)
    else
        table.insert(gate.on_prepared, cb)
    end
end

--- Cheap, non-blocking observer: is the plugin's gate prepared?
---@param name string Plugin name (spec.name)
---@return boolean|nil true prepared, false not yet, nil no gate exists (absent)
function M.is_prepared(name)
    local gate = M._gates[name]
    if gate == nil then
        return nil
    end
    return gate.state == "prepared"
end

--- Cheap, non-blocking observer: is the plugin's gate ready (prepared
--- and setup done)?
---@param name string Plugin name (spec.name)
---@return boolean|nil true ready, false prepared-but-not-ready or pending, nil no gate exists (absent)
function M.is_ready(name)
    local gate = M._gates[name]
    if gate == nil then
        return nil
    end
    return gate.ready == true
end

return M
