require("micro.pack").add "gh:MeanderingProgrammer/render-markdown.nvim"

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    once = true,
    callback = function()
        require("render-markdown").setup {
            -- Visually indent content according to its enclosing heading level.
            indent = {
                enabled = true,
                per_level = 2,
                skip_level = 1,
                skip_heading = true,
            },
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
