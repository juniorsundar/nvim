local M = {}

--- Synchronously get the current tmux session name.
--- @return string|nil session name, or nil if not in tmux / tmux not running.
function M.get_current_session()
    local result = vim.system({ "tmux", "display-message", "-p", "#{session_name}" }, { text = true }):wait()
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return nil
    end
    return (result.stdout:gsub("\n$", ""))
end

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
--- @param cmd string|nil Optional command to run immediately after session creation
--- @return boolean success
function M.create_session(session_name, cmd)
    local command = { "tmux", "new-session", "-d", "-s", session_name }
    if cmd and cmd ~= "" then
        table.insert(command, cmd)
    end
    local result = vim.system(command, { text = true }):wait()
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
