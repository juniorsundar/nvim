-- Minimal async HTTP GET over curl.
local M = {}

local function percent_encode(value)
    return (
        tostring(value):gsub("[^%w%-._~]", function(char)
            return string.format("%%%02X", string.byte(char))
        end)
    )
end

--- GET `opts.url` (with `opts.query` params and `opts.headers`); follows redirects.
--- `cb(err, res)` runs on the main loop: `err = { message }` on curl failure, otherwise
--- `res = { status, body, json? }` where `json` is set for JSON responses.
---@param opts { url: string, query?: table<string, any>, headers?: table<string, string>, timeout?: integer }
---@param cb fun(err: { message: string }?, res: { status: integer, body: string, json: any }?)
function M.request(opts, cb)
    local url = opts.url
    if opts.query and next(opts.query) then
        local parts = {}
        for key, value in pairs(opts.query) do
            parts[#parts + 1] = percent_encode(key) .. "=" .. percent_encode(value)
        end
        url = url .. (url:find("?", 1, true) and "&" or "?") .. table.concat(parts, "&")
    end

    local args = { "curl", "--silent", "--show-error", "--location" }
    vim.list_extend(args, { "--max-time", ("%.3f"):format((opts.timeout or 30000) / 1000) })
    vim.list_extend(args, { "--write-out", "\n%{http_code} %{content_type}" })
    for name, value in pairs(opts.headers or {}) do
        vim.list_extend(args, { "--header", name .. ": " .. value })
    end
    args[#args + 1] = url

    local ok, err = pcall(vim.system, args, { text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                local stderr = vim.trim(result.stderr or "")
                return cb { message = stderr ~= "" and stderr or "micro.http: curl exited with " .. result.code }
            end
            local body, status, content_type = result.stdout:match "^(.*)\n(%d+) ?(.*)$"
            local res = { status = tonumber(status), body = body }
            if content_type:lower():find("json", 1, true) then
                local decoded_ok, decoded = pcall(vim.json.decode, body)
                res.json = decoded_ok and decoded or nil
            end
            cb(nil, res)
        end)
    end)
    if not ok then
        vim.schedule(function()
            cb { message = "micro.http: " .. tostring(err) }
        end)
    end
end

return M
