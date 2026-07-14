local capabilities = require "config.lsp.serve_capabilities"

local vault_root = vim.fs.normalize "/home/juniorsundar/Dropbox/vault"

return {
    cmd = { "markdown-oxide" },
    filetypes = { "markdown" },
    capabilities = capabilities,
    root_dir = function(bufnr, on_dir)
        local path = vim.api.nvim_buf_get_name(bufnr)
        if path ~= "" and vim.startswith(vim.fs.normalize(path), vault_root .. "/") then
            on_dir(vault_root)
        end
    end,
}
