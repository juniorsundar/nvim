M = {
    capabilities = vim.lsp.protocol.make_client_capabilities(),
}

M.capabilities.workspace = {
    didChangeWatchedFiles = {
        dynamicRegistration = true,
    },
    refresh = {
        enabled = true,
    },
}

M.capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
}

local blink_loaded, blink = pcall(require, "blink.cmp")
-- local cmp_loaded, cmp = pcall(require, "cmp_nvim_lsp")
if blink_loaded then
    -- if cmp_loaded then
    M.capabilities = vim.tbl_deep_extend("force", M.capabilities, blink.get_lsp_capabilities(M.capabilities))
    M.capabilities.textDocument.codeLens = { dynamicRegistration = true }
    -- M.capabilities = vim.tbl_deep_extend("force", M.capabilities, cmp.default_capabilities())
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
    callback = function(event)
        local bufnr = event.buf
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if client and client:supports_method "textDocument/codeLens" then
            vim.lsp.codelens.enable()
        end

        vim.keymap.set("n", "<leader>LCl", function()
            vim.lsp.codelens.run()
        end, { buffer = bufnr, desc = "Run CodeLens action" })

        vim.keymap.set("n", "<leader>LCr", function()
            vim.lsp.codelens.enable(true)
        end, { buffer = bufnr, desc = "Force refresh CodeLens" })

        vim.keymap.set("n", "<leader>LCt", function()
            if vim.lsp.codelens.is_enabled() then
                vim.lsp.codelens.enable(false)
            else
                vim.lsp.codelens.enable()
            end
        end, { buffer = bufnr, desc = "Toggle CodeLens" })

        vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
        if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = bufnr,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = bufnr,
                callback = vim.lsp.buf.clear_references,
            })
        end

        if client and client.name == "basedpyright" then
            client.server_capabilities.semanticTokensProvider = nil
        end

        pcall(function()
            vim.keymap.del("n", "K", { buffer = bufnr })
        end)
    end,
})

return M
