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
    -- M.capabilities = vim.tbl_deep_extend("force", M.capabilities, cmp.default_capabilities())
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(event)
        vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                callback = vim.lsp.buf.clear_references,
            })
        end
        if client and client.name == "basedpyright" then
            client.server_capabilities.semanticTokensProvider = nil
        end
        local _, _ = pcall(function()
            vim.keymap.del("n", "K", { buffer = event.buf })
        end)
    end,
})

return M
