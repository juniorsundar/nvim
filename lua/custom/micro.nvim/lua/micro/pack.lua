local M = {}

M.config = {}
M._specs = {}

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

    local orphan_names = vim.tbl_map(function(p)
        return p.spec.name
    end, orphans)

    if opts.force then
        vim.pack.del(orphan_names, { force = false })
        vim.notify("micro.pack: cleaned " .. #orphan_names .. " plugin(s)", vim.log.levels.INFO)
        return
    end

    local msg = "micro.pack: " .. #orphans .. " orphaned plugin(s) found:\n\n"
    for i, p in ipairs(orphans) do
        local status = p.active and " [active]" or ""
        msg = msg .. string.format("  %d. %s%s\n", i, p.spec.name, status)
    end
    msg = msg .. "\nDelete all orphaned plugins?"

    local choice = vim.fn.confirm(msg, "&Yes\n&No", 2, "Question")
    if choice == 1 then
        vim.pack.del(orphan_names, { force = false })
        vim.notify("micro.pack: cleaned " .. #orphan_names .. " plugin(s)", vim.log.levels.INFO)
    else
        vim.notify("micro.pack: clean cancelled", vim.log.levels.INFO)
    end
end

--- Get info about managed plugins. Thin passthrough to vim.pack.get().
---@param names string[]?
---@param opts table?
---@return table[]
function M.get(names, opts)
    return vim.pack.get(names, opts)
end

--- High-level setup hook. Does NOT defer/batch installs — M.add() is
--- always immediate. Use this for future config like on_change hooks.
---@param opts table?
function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend("force", M.config, opts)

    if type(opts.on_change) == "function" then
        local augroup = vim.api.nvim_create_augroup("MicroPack", { clear = true })
        vim.api.nvim_create_autocmd("User", {
            pattern = "PackChanged",
            group = augroup,
            callback = function(args)
                opts.on_change(args.data)
            end,
        })
    end

    if opts.specs and type(opts.specs) == "table" then
        M.add(opts.specs)
    end
end

return M
