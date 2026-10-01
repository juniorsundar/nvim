-- Drives a real headless Neovim child over RPC with real input keys, so the
-- main loop, completion timers and LSP replies behave as in a live editor.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local server = root .. "/tests/support/server.py"

local Editor = {}
Editor.__index = Editor

function Editor.new()
    local sock = vim.fn.tempname()
    local bin = os.getenv "NVIM_BIN" or vim.v.progpath
    local job = vim.fn.jobstart { bin, "--headless", "--clean", "-n", "--listen", sock, "--cmd", "set rtp^=" .. root }
    assert(
        vim.wait(5000, function()
            return vim.uv.fs_stat(sock) ~= nil
        end, 20),
        "editor did not start"
    )
    local self = setmetatable({ job = job, chan = vim.fn.sockconnect("pipe", sock, { rpc = true }) }, Editor)
    self:lua [[vim.o.shortmess = vim.o.shortmess .. "c"; vim.o.swapfile = false]]
    return self
end

function Editor:lua(code, ...)
    return vim.rpcrequest(self.chan, "nvim_exec_lua", code, { ... })
end

function Editor:input(keys)
    vim.rpcrequest(self.chan, "nvim_input", keys)
end

-- Poll a Lua expression (evaluated in the editor) until truthy.
function Editor:wait(expr, timeout)
    local ok = vim.wait(timeout or 3000, function()
        return self:lua("return " .. expr)
    end, 25)
    assert(ok, "timed out waiting for: " .. expr)
end

function Editor:sleep(ms)
    vim.wait(ms)
end

function Editor:state()
    return self:lua [[
        local info = vim.fn.complete_info { "matches", "selected", "preview_bufnr" }
        local words = {}
        for _, item in ipairs(info.matches or {}) do
            words[#words + 1] = item.word
        end
        local preview = {}
        if info.preview_bufnr and vim.api.nvim_buf_is_valid(info.preview_bufnr) then
            preview = vim.api.nvim_buf_get_lines(info.preview_bufnr, 0, -1, false)
        end
        return {
            mode = vim.api.nvim_get_mode().mode,
            lines = vim.api.nvim_buf_get_lines(0, 0, -1, false),
            visible = vim.fn.pumvisible() == 1,
            words = words,
            selected = info.selected,
            preview = preview,
            snippet = vim.snippet.active(),
        }
    ]]
end

--- Starts the scripted server (server.py options in `opts`) for the current buffer.
--- name: client name (distinct names give distinct clients); wrap: launch through micro.completion's cmd guard.
function Editor:server(opts, name, wrap)
    local count = self:lua "return #vim.lsp.get_clients { bufnr = 0 }"
    self:lua(
        [[
        local o, server, name, wrap = ...
        local cmd = { vim.env.PYTHON or "python3", server, vim.json.encode(next(o) and o or vim.empty_dict()) }
        vim.lsp.start {
            name = name,
            cmd = wrap and require("micro.completion").wrap_cmd(cmd) or cmd,
            root_dir = vim.fn.getcwd(),
        }
    ]],
        opts or vim.empty_dict(),
        server,
        name or "probe",
        wrap or false
    )
    self:wait(("#vim.lsp.get_clients { bufnr = 0 } > %d"):format(count))
end

--- Opens a scratch buffer and starts the scripted server through the guarded cmd.
--- opts: lines, row, filetype, buftype, server (server.py options), micro (micro.completion opts)
function Editor:session(opts)
    opts = opts or {}
    self:lua(
        [[
        local o = ...
        require("micro.completion").setup(o.micro or {})
        require("micro.completion_keys").setup()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, o.lines or { "BufThing", "" })
        vim.api.nvim_win_set_cursor(0, { o.row or 2, 0 })
        vim.bo.buftype = o.buftype or ""
        vim.bo.filetype = o.filetype or "probe"
    ]],
        opts
    )
    self:server(opts.server, opts.name, true)
    self:wait [[vim.b.micro_completion_route ~= nil]]
end

function Editor:close()
    vim.fn.jobstop(self.job)
    vim.fn.chanclose(self.chan)
end

return Editor
