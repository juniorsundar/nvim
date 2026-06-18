local M = {}

local DEFAULT_TIMEOUT_MS = 30000

local function noop() end

local function make_error(err_type, message, extra)
    local err = vim.tbl_extend("force", {
        type = err_type,
        message = message,
    }, extra or {})
    return err
end

local function schedule_callback(cb, err, res)
    vim.schedule(function()
        cb(err, res)
    end)
end

local function percent_encode(value)
    return tostring(value):gsub("[^%w%-._~]", function(char)
        return string.format("%%%02X", string.byte(char))
    end)
end

local function build_url(url, query)
    if query == nil then
        return url
    end
    if type(query) ~= "table" then
        return nil, make_error("invalid_option", "micro.http: query must be a table")
    end

    local parts = {}
    for key, value in pairs(query) do
        if value ~= nil then
            local value_type = type(value)
            if value_type ~= "string" and value_type ~= "number" and value_type ~= "boolean" then
                return nil,
                    make_error(
                        "invalid_option",
                        "micro.http: query values must be strings, numbers, booleans, or nil",
                        { key = tostring(key) }
                    )
            end
            table.insert(parts, percent_encode(key) .. "=" .. percent_encode(value))
        end
    end

    if #parts == 0 then
        return url
    end

    local separator = url:find("?", 1, true) and "&" or "?"
    return url .. separator .. table.concat(parts, "&")
end

local function normalise_headers(headers)
    if headers == nil then
        return {}
    end
    if type(headers) ~= "table" then
        return nil, make_error("invalid_option", "micro.http: headers must be a table")
    end

    local out = {}
    for key, value in pairs(headers) do
        if value ~= nil then
            local value_type = type(value)
            if value_type ~= "string" and value_type ~= "number" and value_type ~= "boolean" then
                return nil,
                    make_error(
                        "invalid_option",
                        "micro.http: header values must be strings, numbers, booleans, or nil",
                        { header = tostring(key) }
                    )
            end
            out[tostring(key)] = tostring(value)
        end
    end
    return out
end

local function has_header(headers, name)
    local wanted = name:lower()
    for key, _ in pairs(headers) do
        if tostring(key):lower() == wanted then
            return true
        end
    end
    return false
end

local function read_file(path)
    local file, open_err = io.open(path, "rb")
    if not file then
        return nil, open_err
    end
    local content = file:read "*a"
    file:close()
    return content or ""
end

local function write_file(path, content)
    local file, open_err = io.open(path, "wb")
    if not file then
        return nil, open_err
    end
    file:write(content)
    file:close()
    return true
end

local function unlink(path)
    if path then
        pcall(os.remove, path)
    end
end

local function parse_headers(raw)
    local blocks = {}
    local current = {}

    for line in (raw or ""):gmatch "([^\n]*)\n?" do
        if line == "" and #current == 0 then
            break
        end

        line = line:gsub("\r$", "")
        if line == "" then
            if #current > 0 then
                table.insert(blocks, current)
                current = {}
            end
        else
            table.insert(current, line)
        end
    end

    if #current > 0 then
        table.insert(blocks, current)
    end

    local final = blocks[#blocks] or {}
    local headers = {}
    for index = 2, #final do
        local name, value = final[index]:match "^([^:]+):%s*(.*)$"
        if name then
            local key = name:lower()
            if headers[key] then
                headers[key] = headers[key] .. ", " .. value
            else
                headers[key] = value
            end
        end
    end

    return headers, final
end

local function maybe_decode_json(headers, body)
    local content_type = headers["content-type"]
    if not content_type or not content_type:lower():find("json", 1, true) then
        return nil
    end

    local ok, decoded = pcall(vim.json.decode, body)
    if ok then
        return decoded
    end
    return nil
end

local function timeout_seconds(timeout_ms)
    return string.format("%.3f", timeout_ms / 1000)
end

local function make_handle(state)
    local handle = {}

    function handle:abort()
        state.aborted = true
        if state.proc and not state.done then
            state.proc:kill(15)
        end
    end

    function handle:is_aborted()
        return state.aborted
    end

    return handle
end

--- Return whether curl is available on this system.
---@return boolean
function M.available()
    return vim.fn.executable "curl" == 1
end

--- Start an asynchronous HTTP request using curl via vim.system().
---
--- Example:
--- ```lua
--- require("micro.http").request({
---     url = "http://localhost:5340/search",
---     query = { q = "neovim", format = "json" },
--- }, function(err, res)
---     if err then
---         vim.notify(err.message, vim.log.levels.ERROR)
---         return
---     end
---     vim.print(res.json or res.body)
--- end)
---```
---
---@param opts table Request options: url, method, query, headers, body, json, timeout, follow_redirects, raise_for_status
---@param cb fun(err: table|nil, res: table|nil)? Callback called as cb(err, response)
---@return table handle Request handle with abort() and is_aborted()
function M.request(opts, cb)
    cb = cb or noop
    if type(cb) ~= "function" then
        error "micro.http: callback must be a function"
    end

    local state = {
        aborted = false,
        done = false,
        proc = nil,
    }
    local handle = make_handle(state)

    local function fail(err)
        state.done = true
        schedule_callback(cb, err, nil)
        return handle
    end

    if type(opts) ~= "table" then
        return fail(make_error("invalid_option", "micro.http: opts must be a table"))
    end
    if type(opts.url) ~= "string" or opts.url == "" then
        return fail(make_error("invalid_option", "micro.http: opts.url must be a non-empty string"))
    end
    if not M.available() then
        return fail(make_error("executable_not_found", "micro.http: curl executable not found"))
    end

    local method = tostring(opts.method or "GET"):upper()
    local url, url_err = build_url(opts.url, opts.query)
    if url_err then
        return fail(url_err)
    end

    local headers, header_err = normalise_headers(opts.headers)
    if header_err then
        return fail(header_err)
    end

    if opts.body ~= nil and opts.json ~= nil then
        return fail(make_error("invalid_option", "micro.http: use either opts.body or opts.json, not both"))
    end

    local request_body
    if opts.json ~= nil then
        local ok, encoded = pcall(vim.json.encode, opts.json)
        if not ok then
            return fail(
                make_error("json_encode_error", "micro.http: failed to encode JSON request body", { cause = encoded })
            )
        end
        request_body = encoded
        if not has_header(headers, "content-type") then
            headers["Content-Type"] = "application/json"
        end
        if not has_header(headers, "accept") then
            headers["Accept"] = "application/json"
        end
    elseif opts.body ~= nil then
        if type(opts.body) ~= "string" then
            return fail(make_error("invalid_option", "micro.http: opts.body must be a string"))
        end
        request_body = opts.body
    end

    local timeout = opts.timeout or DEFAULT_TIMEOUT_MS
    if type(timeout) ~= "number" or timeout <= 0 then
        return fail(make_error("invalid_option", "micro.http: opts.timeout must be a positive number of milliseconds"))
    end

    local header_file = vim.fn.tempname()
    local body_file = vim.fn.tempname()
    local request_body_file

    local args = {
        "curl",
        "--silent",
        "--show-error",
        "--max-time",
        timeout_seconds(timeout),
        "--request",
        method,
        "--dump-header",
        header_file,
        "--output",
        body_file,
        "--write-out",
        "%{http_code}",
    }

    if opts.follow_redirects ~= false then
        table.insert(args, "--location")
    end

    for name, value in pairs(headers) do
        table.insert(args, "--header")
        table.insert(args, name .. ": " .. value)
    end

    if request_body ~= nil then
        request_body_file = vim.fn.tempname()
        local ok, write_err = write_file(request_body_file, request_body)
        if not ok then
            unlink(header_file)
            unlink(body_file)
            unlink(request_body_file)
            return fail(make_error("io_error", "micro.http: failed to write request body", { cause = write_err }))
        end
        table.insert(args, "--data-binary")
        table.insert(args, "@" .. request_body_file)
    end

    table.insert(args, url)

    state.proc = vim.system(args, { text = true }, function(result)
        vim.schedule(function()
            state.done = true

            local stdout = result.stdout or ""
            local stderr = result.stderr or ""

            if state.aborted then
                unlink(header_file)
                unlink(body_file)
                unlink(request_body_file)
                cb(make_error("aborted", "micro.http: request aborted"), nil)
                return
            end

            if result.code ~= 0 then
                unlink(header_file)
                unlink(body_file)
                unlink(request_body_file)
                local err_type = result.code == 28 and "timeout" or "curl_error"
                cb(
                    make_error(
                        err_type,
                        stderr ~= "" and vim.trim(stderr) or "micro.http: curl exited with code " .. result.code,
                        {
                            code = result.code,
                            stderr = stderr,
                        }
                    ),
                    nil
                )
                return
            end

            local raw_headers, read_headers_err = read_file(header_file)
            local body, read_body_err = read_file(body_file)
            unlink(header_file)
            unlink(body_file)
            unlink(request_body_file)

            if not raw_headers then
                cb(
                    make_error("io_error", "micro.http: failed to read response headers", { cause = read_headers_err }),
                    nil
                )
                return
            end
            if not body then
                cb(make_error("io_error", "micro.http: failed to read response body", { cause = read_body_err }), nil)
                return
            end

            local status = tonumber(vim.trim(stdout))
            if not status then
                cb(make_error("parse_error", "micro.http: failed to parse curl HTTP status", { stdout = stdout }), nil)
                return
            end

            local response_headers, raw_header_lines = parse_headers(raw_headers)
            local response = {
                status = status,
                headers = response_headers,
                raw_headers = raw_header_lines,
                body = body,
                stderr = stderr,
            }

            local decoded = maybe_decode_json(response_headers, body)
            if decoded ~= nil then
                response.json = decoded
            end

            if opts.raise_for_status and status >= 400 then
                cb(
                    make_error("http_status", "micro.http: HTTP request failed with status " .. status, {
                        status = status,
                        response = response,
                    }),
                    response
                )
                return
            end

            cb(nil, response)
        end)
    end)

    return handle
end

return M
