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
                    "marksman",
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                'kevinhwang91/nvim-ufo',
                dependencies = { 'kevinhwang91/promise-async' },
                config = function()
                    vim.o.foldenable = true
                    -- vim.o.foldlevel = 99
                    vim.o.foldlevelstart = 99
                    vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
                    vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

                    local handler = function(virtText, lnum, endLnum, width, truncate)
                        local newVirtText = {}
                        local suffix = (' 󰁂 %d '):format(endLnum - lnum)
                        local sufWidth = vim.fn.strdisplaywidth(suffix)
                        local targetWidth = width - sufWidth
                        local curWidth = 0
                        for _, chunk in ipairs(virtText) do
                            local chunkText = chunk[1]
                            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                            if targetWidth > curWidth + chunkWidth then
                                table.insert(newVirtText, chunk)
                            else
                                chunkText = truncate(chunkText, targetWidth - curWidth)
                                local hlGroup = chunk[2]
                                table.insert(newVirtText, { chunkText, hlGroup })
                                chunkWidth = vim.fn.strdisplaywidth(chunkText)
                                -- str width returned from truncate() may less than 2nd argument, need padding
                                if curWidth + chunkWidth < targetWidth then
                                    suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                                end
                                break
                            end
                            curWidth = curWidth + chunkWidth
                        end
                        table.insert(newVirtText, { suffix, 'MoreMsg' })
                        return newVirtText
                    end

                    require('ufo').setup({
                        fold_virt_text_handler = handler,
                        provider_selector = function(bufnr, filetype, buftype)
                            if filetype == 'norg' or filetype == 'org' then
                                return ''
                            else
                                return { 'treesitter', 'indent' }
                            end
                        end
                    })

                    vim.api.nvim_create_autocmd("FileType", {
                        pattern = { "norg", "org" },
                        callback = function()
                            require("ufo").detach()
                        end
                    })
                end
            },
        },
        config = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

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

            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
                vim.lsp.handlers.hover, {
                    border = "single"
                }
)
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

            lspconfig.marksman.setup({
                single_file_support = false,
            })

            -- Use LspAttach autocommand to only map the following keys
            -- after the language server attaches to the current buffer
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(event)
                    -- Enable completion triggered by <c-x><c-o>
                    vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                    -- Buffer local mappings.
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
        end,
    },
    {
        'stevearc/conform.nvim',
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff" },
                go = { "gofumpt" },
            },
        },
    },
}
