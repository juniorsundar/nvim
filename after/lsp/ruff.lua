local capabilities = require "config.lsp.serve_capabilities"

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

return {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = { ".git", "pyproject.toml", "ruff.toml", ".ruff.toml" },
    single_file_support = true,
    capabilities = capabilities,
}
