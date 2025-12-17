local capabilities = require "config.lsp.serve_capabilities"

return {
    cmd = { "ty", "server" },
    filetypes = { "python" },
    capabilities = capabilities,
    root_markers = { "ty.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
}
