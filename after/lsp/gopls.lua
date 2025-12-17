local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "gopls" },
    filetypes = { "go", "gomod" },
    root_markers = { "go.mod", "go.sum", ".git" },
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
