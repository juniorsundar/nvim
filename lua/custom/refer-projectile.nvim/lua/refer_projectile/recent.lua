local M = {}

local MAX_RECENT = 20

local function _get_storage_path()
    local data_dir = vim.fn.stdpath "data"
    return data_dir .. "/refer/projectile_recent.lua"
end

local function _ensure_storage_dir()
    local data_dir = vim.fn.stdpath "data" .. "/refer/"
    if vim.fn.isdirectory(data_dir) ~= 1 then
        vim.fn.mkdir(data_dir, "p")
    end
end

function M.load()
    local storage_path = _get_storage_path()
    if vim.fn.filereadable(storage_path) == 1 then
        local chunk = loadfile(storage_path)
        if chunk then
            local ok, result = pcall(chunk)
            if ok and type(result) == "table" then
                return result
            end
        end
    end
    return {}
end

function M.save(projects)
    _ensure_storage_dir()
    local storage_path = _get_storage_path()
    local lines = { "return {" }
    for _, path in ipairs(projects) do
        table.insert(lines, '  "' .. path:gsub('"', '\\"') .. '",')
    end
    table.insert(lines, "}")
    local content = table.concat(lines, "\n")
    local f = io.open(storage_path, "w")
    if f then
        f:write(content)
        f:close()
    end
end

function M.add(path)
    local projects = M.load()
    path = vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("/+$", "")

    for _, p in ipairs(projects) do
        if p == path then
            return
        end
    end

    table.insert(projects, path)

    while #projects > MAX_RECENT do
        table.remove(projects, 1)
    end

    M.save(projects)
end

return M
