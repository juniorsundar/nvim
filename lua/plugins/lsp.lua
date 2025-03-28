return {
    {
        "williamboman/mason.nvim",
        event = "LspAttach",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup {
                ensure_installed = {
                    "lua_ls",
                    "marksman",
                },
            }
        end,
    },
    {
        "neovim/nvim-lspconfig",
        -- event = "VeryLazy",
        dependencies = {},
        config = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            -- capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
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

            local lspconfig = require "lspconfig"

            local function signHl(name)
                local hl = "DiagnosticSign" .. name
                return hl
            end

            vim.diagnostic.config {
                virtual_lines = {
                    current_line = true
                },
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = "󰅙",
                        [vim.diagnostic.severity.INFO] = "󰋼",
                        [vim.diagnostic.severity.HINT] = "󰌵",
                        [vim.diagnostic.severity.WARN] = "",
                    },
                    linehl = {
                        [vim.diagnostic.severity.ERROR] = signHl("Error"),
                        [vim.diagnostic.severity.INFO] = signHl("Info"),
                        [vim.diagnostic.severity.HINT] = signHl("Hint"),
                        [vim.diagnostic.severity.WARN] = signHl("Warn"),
                    },
                    numhl = {
                        [vim.diagnostic.severity.ERROR] = signHl("Error"),
                        [vim.diagnostic.severity.INFO] = signHl("Info"),
                        [vim.diagnostic.severity.HINT] = signHl("Hint"),
                        [vim.diagnostic.severity.WARN] = signHl("Warn"),
                    },
                },
                underline = true,
                update_in_insert = false,
            }


            lspconfig.lua_ls.setup {
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

            lspconfig.basedpyright.setup {
                capabilities = capabilities,
                settings = {
                    basedpyright = {
                        analysis = {
                            typeCheckingMode = "standard",
                        },
                    },
                },
            }

            lspconfig.ruff.setup {
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

            lspconfig.clangd.setup {
                capabilities = capabilities,
                root_dir = lspconfig.util.root_pattern("compile_commands.json", ".clangd"),
            }

            lspconfig.zls.setup {
                capabilities = capabilities,
            }

            lspconfig.rust_analyzer.setup {
                capabilities = capabilities,
            }

            lspconfig.gopls.setup {
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

            lspconfig.marksman.setup {
                single_file_support = false,
            }

            -- Use LspAttach autocommand to only map the following keys
            -- after the language server attaches to the current buffer
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(event)
                    -- Enable completion triggered by <c-x><c-o>
                    vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                    -- Set the foldtext option to use the custom function
                    vim.opt.foldmethod = "expr"
                    vim.o.foldlevel = 99
                    vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

                    function _G.custom_foldtext()
                        local fold_start = vim.v.foldstart
                        local first_line = vim.fn.getline(fold_start)
                        return first_line
                    end

                    -- Assign the custom function to foldtext
                    vim.opt.foldtext = "v:lua.custom_foldtext()"
                    -- Optional: Remove fold column filler characters for a cleaner look
                    vim.opt.fillchars:append { fold = " " }
                    --
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
                    end
                    vim.keymap.del("n", "K", { buffer = event.buf })
                end,
            })
        end,
    },
    {
        "stevearc/conform.nvim",
        event = "VeryLazy",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff" },
                go = { "gofumpt" },
            },
        },
    },
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
}
