local Editor = require "tests.support.editor"

-- The repo starts servers through lsp/*.lua configs enabled from ftplugin files. These specs
-- reproduce that flow: one shared decoration point wraps every config's `cmd` before
-- vim.lsp.enable() can start a client.
describe("micro.completion (startup wiring)", function()
    local ed, root, log

    before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/proj/.git", "p")
        vim.fn.writefile({ "BufThing", "" }, root .. "/proj/a.probe")
        vim.fn.writefile({ "Other", "" }, root .. "/proj/b.probe")
        log = root .. ".log"
        ed = Editor.new()
    end)
    after_each(function()
        ed:close()
        vim.fn.delete(root, "rf")
        vim.fn.delete(log)
    end)

    local server = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h") .. "/support/server.py"

    -- Registers a probe server config the way after/lsp/*.lua does (a plain `cmd` table).
    local function enable_probe(opts)
        ed:lua(
            [[
            local root, server, o = ...
            require("micro.completion").setup {}
            vim.filetype.add { extension = { probe = "probe" } }
            vim.lsp.config("probe", {
                cmd = { "python3", server, vim.json.encode(o) },
                filetypes = { "probe" },
                root_markers = { ".git" },
            })
            vim.lsp.enable("probe")
            vim.cmd.edit(root .. "/proj/a.probe")
        ]],
            root,
            server,
            opts or { delays = { 20 }, log = log }
        )
    end

    it("guards a client started through lsp.enable from its first request", function()
        enable_probe { delays = { 400 }, log = log }
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        ed:input "GiTh"
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log))
        ed:input "<C-e>"
        ed:sleep(800)
        assert.is_false(vim.tbl_contains(ed:state().words, "LspThing")) -- the late reply was dropped
    end)

    it("starts wrapped servers in the same directory native would", function()
        local cwd_log = root .. ".cwd"
        enable_probe { delays = { 20 }, cwd_log = cwd_log }
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(cwd_log))
        local expected = ed:lua [[
            local c = vim.lsp.get_clients({ bufnr = 0 })[1].config
            return c.cmd_cwd or (vim.fn.has "nvim-0.13" == 1 and c.root_dir) or vim.fn.getcwd()
        ]]
        -- Compare real paths: the temp directory may sit behind a symlink.
        assert.equals(vim.uv.fs_realpath(expected), vim.uv.fs_realpath(vim.fn.readfile(cwd_log)[1]))
        vim.fn.delete(cwd_log)
    end)

    it("leaves a missing executable alone so native still skips it", function()
        ed:lua [[
            require("micro.completion").setup {}
            vim.lsp.config("ghost", { cmd = { "definitely-not-installed" }, filetypes = { "probe" } })
            vim.lsp.enable("ghost")
        ]]
        assert.equals("table", ed:lua [[return type(vim.lsp.config["ghost"].cmd)]])
    end)

    it("does not stack wrappers across repeated setup and decoration", function()
        enable_probe()
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        local same = ed:lua [[
            require("micro.completion").setup {}
            require("micro.completion").decorate "probe"
            local cmd = vim.lsp.config["probe"].cmd
            return require("micro.completion").wrap_cmd(cmd) == cmd
        ]]
        assert.is_true(same)
        -- one wrapper level: a late reply is still dropped exactly once and a fresh one shown
        assert.equals("function", ed:lua [[return type(vim.lsp.config["probe"].cmd)]])
    end)

    it("reuses the guarded client for a second buffer", function()
        enable_probe()
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        local first = ed:lua [[return vim.lsp.get_clients({ bufnr = 0 })[1].id]]
        ed:lua("vim.cmd.edit(...)", root .. "/proj/b.probe")
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        assert.equals(first, ed:lua [[return vim.lsp.get_clients({ bufnr = 0 })[1].id]])
    end)

    it("guards the client again after disable and re-enable", function()
        enable_probe { delays = { 400 }, log = log }
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        ed:lua [[vim.lsp.enable("probe", false)]]
        ed:wait [[#vim.lsp.get_clients() == 0]]
        ed:lua [[vim.lsp.enable("probe")]]
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        ed:input "GiTh"
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log))
        ed:input "<C-e>"
        ed:sleep(800)
        assert.is_false(vim.tbl_contains(ed:state().words, "LspThing"))
    end)

    it("guards a config re-sourced with a plain cmd after setup", function()
        enable_probe { delays = { 400 }, log = log }
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        ed:lua(
            [[
            local server, o = ...
            vim.lsp.enable("probe", false)
            vim.wait(3000, function() return #vim.lsp.get_clients() == 0 end)
            vim.lsp.config("probe", { cmd = { "python3", server, vim.json.encode(o) } })
            vim.lsp.enable "probe"
        ]],
            server,
            { delays = { 400 }, log = log }
        )
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        ed:input "GiTh"
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log))
        ed:input "<C-e>"
        ed:sleep(800)
        assert.is_false(vim.tbl_contains(ed:state().words, "LspThing"))
    end)

    it("routes and guards a server that registers completion dynamically", function()
        enable_probe { delays = { 400 }, log = log, dynamic = true }
        ed:wait [[#vim.lsp.get_clients { bufnr = 0 } > 0]]
        ed:wait [[vim.lsp.get_clients({ bufnr = 0 })[1]:supports_method("textDocument/completion", 0)]]
        ed:input "GiTh"
        ed:wait [[vim.bo.complete == ".,o"]]
        ed:wait(("vim.fn.filereadable(%q) == 1"):format(log)) -- native completion is enabled for this client
        ed:input "<C-e>"
        ed:sleep(800)
        assert.is_false(vim.tbl_contains(ed:state().words, "LspThing"))
    end)
end)
