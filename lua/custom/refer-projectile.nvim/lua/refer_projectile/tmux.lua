local M = {}

--- Synchronously list all tmux sessions.
--- @return string[] session names, or {} if tmux is not running.
function M.list_sessions()
    local result = vim.system({ "tmux", "list-sessions", "-F", "#S" }, { text = true }):wait()
    if result.code ~= 0 then
        return {}
    end
    local sessions = {}
    for line in (result.stdout or ""):gmatch "[^\n]+" do
        table.insert(sessions, line)
    end
    return sessions
end

--- Asynchronously switch to a tmux session by name.
--- @param session_name string
function M.switch_session(session_name)
    vim.system({ "tmux", "switch-client", "-t", session_name }, nil, function(result)
        if result.code ~= 0 then
            vim.schedule(function()
                vim.notify(
                    "refer-projectile: failed to switch tmux session: " .. (result.stderr or ""),
                    vim.log.levels.ERROR
                )
            end)
        end
    end)
end

--- Synchronously create a new detached tmux session.
--- @param session_name string
--- @return boolean success
function M.create_session(session_name)
    local result = vim.system({ "tmux", "new-session", "-d", "-s", session_name }, { text = true }):wait()
    return result.code == 0
end

--- Asynchronously capture the pane output of a tmux session.
--- Uses TMUX="" in env to avoid "no current client" errors when called from inside Neovim.
--- @param session_name string
--- @param callback fun(output: string)
function M.capture_pane(session_name, callback)
    vim.system(
        { "tmux", "capture-pane", "-p", "-e", "-t", session_name .. ":0.0" },
        { text = true, env = { TMUX = "" } },
        function(result)
            vim.schedule(function()
                if result.code ~= 0 then
                    callback ""
                else
                    callback(result.stdout or "")
                end
            end)
        end
    )
end

return M
