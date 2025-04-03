local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require('blink.cmp').get_lsp_capabilities(capabilities))

capabilities.workspace = {
    didChangeWatchedFiles = {
        dynamicRegistration = true,
    },
}
capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
}

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(event)
        vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

        vim.opt.foldmethod = "expr"
        vim.o.foldlevel = 99
        vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

        function _G.custom_foldtext()
            local fold_start = vim.v.foldstart
            local first_line = vim.fn.getline(fold_start)
            return first_line
        end

        vim.opt.foldtext = "v:lua.custom_foldtext()"
        vim.opt.fillchars:append { fold = " " }
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                callback = vim.lsp.buf.clear_references,
            })
        end
        vim.keymap.del("n", "K", { buffer = event.buf })
    end,
})

local momentary_virtual_lines_active = false
vim.keymap.set('n', '<C-w>d', function()
    vim.diagnostic.config({ virtual_lines = { current_line = true } })
    momentary_virtual_lines_active = true
end, { desc = 'Show momentary diagnostic virtual lines (current line)', remap = true })

local augroup = vim.api.nvim_create_augroup('MomentaryVirtualLines', { clear = true })

vim.api.nvim_create_autocmd('CursorMoved', {
    group = augroup,
    pattern = '*', -- Apply in all buffers
    callback = function()
        if momentary_virtual_lines_active then
            local current_config = vim.diagnostic.config().virtual_lines
            if type(current_config) == 'table' and current_config.current_line == true then
                vim.diagnostic.config({ virtual_lines = false })
            end
            momentary_virtual_lines_active = false
        end
    end,
})

---- LSP SETUP ----

local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

vim.diagnostic.config {
    virtual_lines = false,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰅙",
            [vim.diagnostic.severity.INFO] = "󰋼",
            [vim.diagnostic.severity.HINT] = "󰌵",
            [vim.diagnostic.severity.WARN] = "",
        },
        linehl = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.WARN] = "",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
            [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
            [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
            [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
        },
    },
    underline = true,
    update_in_insert = false,
    virtual_text = false
}


vim.lsp.config["lua-language-server"] = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
                checkThirdParty = false,
                library = {
                    "${3rd}/luv/library",
                    unpack(vim.api.nvim_get_runtime_file("", true)),
                },
            },
            completion = {
                callSnippet = "Replace",
            },
            hint = {
                enable = true,
            },
        },
    },
}

vim.lsp.config["basedpyright"] = {
    cmd = { 'basedpyright-langserver', '--stdio' },
    filetypes = { "python" },
    capabilities = capabilities,
    settings = {
        basedpyright = {
            analysis = {
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = 'openFilesOnly',
            },
        },
    },
    single_file_support = true,
    root_markers = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
        'pyrightconfig.json',
        '.git',
    }
}

vim.lsp.config["ruff"] = {
    cmd = { 'ruff', 'server' },
    filetypes = { "python" },
    root_markers = { '.git', 'pyproject.toml', 'ruff.toml', '.ruff.toml' },
    single_file_support = true,
    capabilities = capabilities,
}

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client == nil then
            return
        end
        if client.name == "ruff" then
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
        end
    end,
    desc = "LSP: Disable hover capability from Ruff",
})

vim.lsp.config["clangd"] = {
    cmd = { "clangd" },
    filetypes = { "cpp", "hpp", "h", "c" },
    root_markers = { "compile_commands.json", ".clangd", ".git" },
    capabilities = capabilities,
}

vim.lsp.config["zls"] = {
    cmd = { "zls" },
    filetypes = { "zig" },
    root_markers = { 'zls.json', 'build.zig', '.git' },
    single_file_support = true,
    capabilities = capabilities,
}

vim.lsp.config["gopls"] = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod" },
    root_markers = { 'go.mod', 'go.sum', '.git' },
    single_file_support = true,
    capabilities = capabilities,
    settings = {
        gopls = {
            ["ui.inlayhint.hints"] = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
            },
        },
    },
}

vim.lsp.config["rust-analyzer"] = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { 'Cargo.toml', '.git' },
    single_file_support = true,
    capabilities = capabilities,
}
