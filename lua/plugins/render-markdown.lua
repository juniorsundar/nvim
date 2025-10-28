local M = {
    source = "MeanderingProgrammer/render-markdown.nvim",
    depends = { "nvim-treesitter/nvim-treesitter" }, -- if you use the mini.nvim suite
    config = function()
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
                    doing = { raw = "[/]", rendered = "󰥔", highlight = "RenderMarkdownTodo", scope_highlight = nil },
                },
            },
        }
    end,
}

return M
