return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "basedpyright",
                    "ruff",
                    "clangd",
                    "rust_analyzer",
                    "gopls",
                    "markdown_oxide",
                    "marksman",
                    "ltex"
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        -- lazy = false, -- REQUIRED: tell lazy.nvim to start this plugin at startup
        -- dependencies = {
        -- 	-- main one
        -- 	{ "ms-jpq/coq_nvim", branch = "coq" },
        --
        -- 	-- 9000+ Snippets
        -- 	{ "ms-jpq/coq.artifacts", branch = "artifacts" },
        --
        -- 	-- lua & third party sources -- See https://github.com/ms-jpq/coq.thirdparty
        -- 	-- Need to **configure separately**
        -- 	{ "ms-jpq/coq.thirdparty", branch = "3p" },
        -- 	-- - shell repl
        -- 	-- - nvim lua api
        -- 	-- - scientific calculator
        -- 	-- - comment banner
        -- 	-- - etc
        -- },
        -- init = function()
        -- 	vim.g.coq_settings = {
        -- 		auto_start = true, -- if you want to start COQ at startup
        -- 		-- Your COQ settings here
        -- 		display = {
        --                   mark_highlight_group = "NormalFloat",
        -- 			preview = {
        -- 				border = {
        -- 					{ "╭", "Normal" },
        -- 					{ "─", "Normal" },
        -- 					{ "╮", "Normal" },
        -- 					{ "│", "Normal" },
        -- 					{ "╯", "Normal" },
        -- 					{ "─", "Normal" },
        -- 					{ "╰", "Normal" },
        -- 					{ "│", "Normal" },
        -- 				},
        -- 			},
        -- 			icons = {
        -- 				mode = "short",
        -- 			},
        -- 		},
        -- 	}
        -- end,
        config = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
            -- capabilities = vim.tbl_deep_extend("force", capabilities, require("coq").lsp_ensure_capabilities())

            capabilities.workspace = {
                didChangeWatchedFiles = {
                    dynamicRegistration = true,
                },
            }
            capabilities.textDocument.foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true
            }

            local lspconfig = require("lspconfig")

            local function lspSymbol(name, icon)
                local hl = "DiagnosticSign" .. name
                vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
            end

            lspSymbol("Error", "󰅙")
            lspSymbol("Info", "󰋼")
            lspSymbol("Hint", "󰌵")
            lspSymbol("Warn", "")

            vim.diagnostic.config({
                virtual_text = {
                    prefix = "",
                },
                signs = true,
                underline = true,
                update_in_insert = false,
            })

            --  LspInfo window borders
            local win = require("lspconfig.ui.windows")
            local _default_opts = win.default_opts

            win.default_opts = function(options)
                local opts = _default_opts(options)
                opts.border = "single"
                return opts
            end

            lspconfig.lua_ls.setup({
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
            })

            lspconfig.basedpyright.setup({
                capabilities = capabilities,
                settings = {
                    basedpyright = {
                        analysis = {
                            typeCheckingMode = "standard",
                        },
                    },
                },
            })

            lspconfig.ruff.setup({
                capabilities = capabilities,
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client == nil then
                        return
                    end
                    if client.name == 'ruff' then
                        -- Disable hover in favor of Pyright
                        client.server_capabilities.hoverProvider = false
                    end
                end,
                desc = 'LSP: Disable hover capability from Ruff',
            })

            lspconfig.clangd.setup({
                capabilities = capabilities,
                root_dir = lspconfig.util.root_pattern("compile_commands.json", ".clangd"),
            })

            lspconfig.rust_analyzer.setup({
                capabilities = capabilities,
            })

            lspconfig.gopls.setup({
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
            })

            lspconfig.markdown_oxide.setup({
                capabilities = capabilities,
                on_attach = function(_, bufnr)
                    -- refresh codelens on TextChanged and InsertLeave as well
                    vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "CursorHold", "LspAttach" }, {
                        buffer = bufnr,
                        callback = vim.lsp.codelens.refresh,
                    })
                    -- trigger codelens refresh
                    vim.api.nvim_exec_autocmds("User", { pattern = "LspAttached" })
                end,
            })

            lspconfig.marksman.setup({
                single_file_support = false,
            })

            lspconfig.ltex.setup({
                autostart = false,
                capabilities = capabilities,
                filetypes = { "norg" },
                settings = {
                    ltex = {
                        enabled = { "norg" },
                        language = "en-GB",
                        checkFrequency = "save",
                    },
                    dictionary = (function()
                        -- For dictionary, search for files in the runtime to have
                        -- and include them as externals the format for them is
                        -- dict/{LANG}.txt
                        --
                        -- Also add dict/default.txt to all of them
                        local files = {}
                        for _, file in ipairs(vim.api.nvim_get_runtime_file("dict/*", true)) do
                            local lang = vim.fn.fnamemodify(file, ":t:r")
                            local fullpath = vim.fs.normalize(file, ":p")
                            files[lang] = { ":" .. fullpath }
                        end

                        if files.default then
                            for lang, _ in pairs(files) do
                                if lang ~= "default" then
                                    vim.list_extend(files[lang], files.default)
                                end
                            end
                            files.default = nil
                        end
                        return files
                    end)(),
                }
            })

            -- Use LspAttach autocommand to only map the following keys
            -- after the language server attaches to the current buffer
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(event)
                    -- Enable completion triggered by <c-x><c-o>
                    vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                    -- Buffer local mappings.
                    -- See `:help vim.lsp.*` for documentation on any of the below functions
                    -- local opts = { buffer = event.buf }
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
                        vim.keymap.del("n", "K", { buffer = event.buf })
                    end
                end,
            })

            -- Peek definition function that opens the definition in a horizontal split
            local function peek_definition()
                local params = vim.lsp.util.make_position_params()
                vim.lsp.buf_request(0, "textDocument/definition", params, function(_, result, ctx, _)
                    if not result or vim.tbl_isempty(result) then
                        print("Definition not found")
                        return
                    end

                    -- Use the first result, can be enhanced to handle multiple results
                    local location = result[1]
                    local uri = location.uri or location.targetUri
                    local range = location.range or location.targetRange

                    local bufnr = vim.uri_to_bufnr(uri)
                    vim.fn.bufload(bufnr)

                    -- Open the definition in a horizontal split
                    vim.cmd("split")
                    vim.api.nvim_set_current_buf(bufnr)

                    -- Move the cursor to the definition line
                    vim.api.nvim_win_set_cursor(
                        vim.api.nvim_get_current_win(),
                        { range.start.line + 1, range.start.character }
                    )

                    -- Optionally, adjust the view to center the cursor line
                    vim.cmd("normal! zz")
                end)
            end
            -- Map the peek_definition function to a key
            -- vim.keymap.set(
            --     "n",
            --     "<Leader>Ld",
            --     peek_definition,
            --     { noremap = true, silent = true, desc = "Definition (Peek)" }
            -- )

            local function peek_declaration()
                local params = vim.lsp.util.make_position_params()
                vim.lsp.buf_request(0, "textDocument/declaration", params, function(_, result, ctx, _)
                    if not result or vim.tbl_isempty(result) then
                        print("Declaration not found")
                        return
                    end

                    -- Use the first result, can be enhanced to handle multiple results
                    local location = result[1]
                    local uri = location.uri or location.targetUri
                    local range = location.range or location.targetRange

                    local bufnr = vim.uri_to_bufnr(uri)
                    vim.fn.bufload(bufnr)

                    -- Open the definition in a horizontal split
                    vim.cmd("split")
                    vim.api.nvim_set_current_buf(bufnr)

                    -- Move the cursor to the definition line
                    vim.api.nvim_win_set_cursor(
                        vim.api.nvim_get_current_win(),
                        { range.start.line + 1, range.start.character }
                    )

                    -- Optionally, adjust the view to center the cursor line
                    vim.cmd("normal! zz")
                end)
            end
            -- Map the peek_definition function to a key
            vim.keymap.set(
                "n",
                "<Leader>Lc",
                peek_declaration,
                { noremap = true, silent = true, desc = "Declaration (Peek)" }
            )

            local function peek_implementation()
                local params = vim.lsp.util.make_position_params()
                vim.lsp.buf_request(0, "textDocument/implementation", params, function(_, result, ctx, _)
                    if not result or vim.tbl_isempty(result) then
                        print("Implementation not found")
                        return
                    end

                    -- Use the first result, can be enhanced to handle multiple results
                    local location = result[1]
                    local uri = location.uri or location.targetUri
                    local range = location.range or location.targetRange

                    local bufnr = vim.uri_to_bufnr(uri)
                    vim.fn.bufload(bufnr)

                    -- Open the definition in a horizontal split
                    vim.cmd("split")
                    vim.api.nvim_set_current_buf(bufnr)

                    -- Move the cursor to the definition line
                    vim.api.nvim_win_set_cursor(
                        vim.api.nvim_get_current_win(),
                        { range.start.line + 1, range.start.character }
                    )

                    -- Optionally, adjust the view to center the cursor line
                    vim.cmd("normal! zz")
                end)
            end
            -- Map the peek_definition function to a key
            vim.keymap.set(
                "n",
                "<Leader>Li",
                peek_implementation,
                { noremap = true, silent = true, desc = "Implementation (Peek)" }
            )
        end,
    },
    {
        'stevearc/conform.nvim',
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                -- Conform will run multiple formatters sequentially
                python = { "ruff" },
                go = { "gofumpt" },
            },
        },
    },
    {
        "nvimdev/lspsaga.nvim",
        event = "LspAttach",
        config = function()
            require("lspsaga").setup({
                lightbulb = {
                    enable = false,
                    sign = false,
                },
                ui = {
                    -- currently only round theme
                    border = "rounded",
                    lines = { "└", "├", "│", "─", "┌" },
                    kind = require("catppuccin.groups.integrations.lsp_saga").custom_kind(),
                },
            })
        end,
    },
}
