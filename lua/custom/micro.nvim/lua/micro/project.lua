local obj = vim.system({ "tmux", "list-session" }, { text = true }):wait()
local sessions = vim.split(obj.stdout, "\n")
local vim_sessions = {}

for _, v in ipairs(sessions) do
    if v:find("", 1, true) then
        table.insert(vim_sessions, vim.split(v, ":")[1])
    end
end

vim.ui.select(vim_sessions, { prompt = "Switch session: " }, function(item, _)
    vim.system({ "tmux", "switch-client", "-t", item }, nil, function(res)
        if res.code ~= 0 then
            vim.notify("Failed to switch session: " .. (res.stderr or "unknown error"), vim.log.levels.ERROR)
        end
    end)
end)
