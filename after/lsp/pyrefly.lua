local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "pyrefly", "lsp" },
    filetypes = { "python" },
    capabilities = capabilities,
    root_markers = {
        "pyrefly.toml",
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        ".git",
    },
    on_exit = function(code, _, _)
        vim.notify("Closing Pyrefly LSP exited with code: " .. code, vim.log.levels.INFO)
    end,
}
