local M = {
    sessions_map_dir = vim.fn.stdpath "data" .. "/micro/sessions/",
    sessions_map_file = "sessions.lua",
}

local default = {
    auto_save = true,
    auto_reload = false,
}

local function get_map_path()
    return M.sessions_map_dir .. M.sessions_map_file
end

local function read_map()
    local path = get_map_path()
    if vim.fn.filereadable(path) == 1 then
        local chunk = loadfile(path)
        if chunk then
            return chunk() or {}
        end
    end
    return {}
end

local function write_map(map)
    local path = get_map_path()
    local content = "return " .. vim.inspect(map)
    local lines = vim.split(content, "\n")
    vim.fn.writefile(lines, path)
end

local ensure_data_dirs = function()
    local dir_exists = vim.fn.isdirectory(M.sessions_map_dir)
    if dir_exists == 0 then
        vim.fn.mkdir(M.sessions_map_dir, "p")
    end

    local full_path = get_map_path()
    if vim.fn.filereadable(full_path) == 0 then
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

    local session_file = M.sessions_map_dir .. map[cwd]
    vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
end

M.load_session = function()
    local cwd = vim.fn.getcwd()
    local map = read_map()

    if map[cwd] then
        local session_file = M.sessions_map_dir .. map[cwd]
        if vim.fn.filereadable(session_file) == 1 then
            vim.cmd("source " .. vim.fn.fnameescape(session_file))
        end
    end
end

local function setup_autocmds()
    local group = vim.api.nvim_create_augroup("MicroSession", { clear = true })

    if default.auto_reload then
        vim.api.nvim_create_autocmd("VimEnter", {
            group = group,
            callback = M.load_session,
        })
    end

    if default.auto_save then
        vim.api.nvim_create_autocmd("ExitPre", {
            group = group,
            callback = M.save_session,
        })
    end
end

M.setup = function(opts)
    default = vim.tbl_deep_extend("force", default, opts or {})
    setup_autocmds()
end

return M
