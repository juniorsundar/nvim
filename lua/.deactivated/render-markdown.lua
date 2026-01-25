MiniDeps.later(function()
    MiniDeps.add {
        source = "MeanderingProgrammer/render-markdown.nvim",
        depends = { "nvim-treesitter/nvim-treesitter" },
    }
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        once = true,
        callback = function()
            require("render-markdown").setup {
                completions = {
                    -- lsp = { enabled = true },
                    blink = { enabled = true },
                },
                render_modes = true,
                checkbox = {
                    custom = {
                        cancelled = {
                            raw = "[-]",
                            rendered = "",
                            highlight = "RenderMarkdownDash",
                            scope_highlight = "RenderMarkdownDash",
                        },
                        doing = {
                            raw = "[/]",
                            rendered = "󰥔",
                            highlight = "RenderMarkdownTodo",
                            scope_highlight = nil,
                        },
                    },
                },
            }
        end,
    })
end)
