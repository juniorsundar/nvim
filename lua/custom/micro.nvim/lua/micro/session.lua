local M = {}

local dir = vim.fn.stdpath "data" .. "/micro/sessions/"
local map_path = dir .. "sessions.lua"

local defaults = {
    auto_save = true,
    auto_reload = false,
}
local config = defaults

local function read_map()
    if vim.fn.filereadable(map_path) == 1 then
        local chunk = loadfile(map_path)
        if chunk then
            return chunk() or {}
        end
    end
    return {}
end

local function write_map(map)
    local content = "return " .. vim.inspect(map)
    local lines = vim.split(content, "\n")
    vim.fn.writefile(lines, map_path)
end

local ensure_data_dirs = function()
    vim.fn.mkdir(dir, "p")
    if vim.fn.filereadable(map_path) == 0 then
        write_map {}
    end
end

M.save_session = function()
    ensure_data_dirs()

    local cwd = vim.fn.getcwd()
    local map = read_map()

    if not map[cwd] then
        math.randomseed(os.time())
        local uid = tostring(math.random(1000000, 9999999))
        map[cwd] = uid .. ".vim"
        write_map(map)
    end

    local session_file = dir .. map[cwd]
    vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
end

M.load_session = function()
    local cwd = vim.fn.getcwd()
    local map = read_map()

    if map[cwd] then
        local session_file = dir .. map[cwd]
        if vim.fn.filereadable(session_file) == 1 then
            vim.cmd("source " .. vim.fn.fnameescape(session_file))
        end
    end
end

local function setup_autocmds()
    local group = vim.api.nvim_create_augroup("MicroSession", { clear = true })

    if config.auto_reload then
        vim.api.nvim_create_autocmd("VimEnter", {
            group = group,
            callback = M.load_session,
        })
    end

    if config.auto_save then
        vim.api.nvim_create_autocmd("ExitPre", {
            group = group,
            callback = M.save_session,
        })
    end
end

M.setup = function(opts)
    config = vim.tbl_deep_extend("force", defaults, opts or {})
    setup_autocmds()
end

M.subcommands = {
    session = {
        save = M.save_session,
        load = M.load_session,
    },
}

return M
