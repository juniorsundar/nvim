local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "harper-ls", "--stdio" },
    capabilities = capabilities,
    single_file_support = true,
    filetypes = { "markdown", "text", "tex", "typst" },
    settings = {
        ["harper-ls"] = {
            dialect = "British",
        },
    },
}
