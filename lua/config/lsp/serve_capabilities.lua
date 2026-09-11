local capabilities = vim.lsp.protocol.make_client_capabilities()

local blink_loaded, blink = pcall(require, "blink.cmp")
if blink_loaded then
    capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities(capabilities))
end

-- Some servers (e.g. lua-language-server) only register `completionProvider`
-- dynamically via `client/registerCapability` when we advertise dynamic
-- registration support for completion. blink.cmp's LSP source only checks
-- the static `server_capabilities.completionProvider`, so it never sees a
-- dynamically-registered one and silently excludes the client. Disabling
-- dynamicRegistration here makes such servers declare completionProvider
-- statically in `initialize` instead.
capabilities.textDocument.completion.dynamicRegistration = false

capabilities.textDocument.codeLens = {
    dynamicRegistration = true,
    refreshSupport = true,
}
capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
}
capabilities.workspace = {
    didChangeWatchedFiles = {
        dynamicRegistration = true,
    },
    inlayHint = { refreshSupport = true },
}

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
    callback = function(event)
        local bufnr = event.buf
        local client = vim.lsp.get_client_by_id(event.data.client_id)

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

return capabilities
