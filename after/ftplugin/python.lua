vim.keymap.set("n", "<tab>", "za", { noremap = false, silent = true, desc = "Expand folding" })

local capabilities = require "config.lsp.serve_capabilities"

vim.lsp.config["basedpyright"] = {
    cmd = { "basedpyright-langserver", "--stdio" },
    filetypes = { "python" },
    capabilities = capabilities,
    settings = {
        basedpyright = {
            analysis = {
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
            },
        },
    },
    single_file_support = true,
    root_markers = {
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        "pyrightconfig.json",
        ".git",
    },
}

vim.lsp.config["ruff"] = {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = { ".git", "pyproject.toml", "ruff.toml", ".ruff.toml" },
    single_file_support = true,
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

vim.lsp.enable {
    "basedpyright",
    "ruff",
}
