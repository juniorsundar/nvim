---@type table
vim.lsp.autohover = {
    enabled = true,
    delay = 2000,
    opts = {
        border = "rounded",
        relative = "editor",
        offset_x = vim.o.columns
    }
}
vim.o.updatetime = vim.lsp.autohover.delay

local lsp_hover_augroup = vim.api.nvim_create_augroup("LspHoverOnHold", { clear = true })

vim.api.nvim_create_autocmd("CursorHold", {
    group = lsp_hover_augroup,
    pattern = "*",
    callback = function()
        if not vim.lsp.autohover then
            return
        end
        if not vim.lsp.autohover.enabled then
            return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients { bufnr = bufnr }

        ---@type boolean
        local has_hover_provider = false
        for _, client in ipairs(clients) do
            if client and client.server_capabilities and client.server_capabilities.hoverProvider then
                has_hover_provider = true
                break
            end
        end

        if not has_hover_provider then
            return
        end

        local handler = function(err, result, _, _)
            if err or not result or not result.contents then
                return
            end

            local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)

            if vim.tbl_isempty(lines) then
                return
            end

            vim.lsp.util.open_floating_preview(lines, "markdown", vim.lsp.autohover.opts)
        end

        local params = vim.lsp.util.make_position_params(0, "utf-32")
        vim.lsp.buf_request(bufnr, "textDocument/hover", params, handler)
    end,
    desc = "Show LSP hover documentation on CursorHold (silently ignores empty responses)",
})

local function toggle_auto_hover()
    if not vim.lsp.autohover then
        vim.notify("`vim.lsp.autohover` doesn't exists!", vim.log.levels.WARN, { title = "LSP" })
        return
    end
    if not vim.lsp.autohover.enabled then
        vim.notify("`vim.lsp.autohover.enabled` doesn't exists!", vim.log.levels.WARN, { title = "LSP" })
        return
    end
    vim.lsp.autohover.enabled = not vim.lsp.autohover.enabled
    if vim.lsp.autohover.enabled then
        vim.notify("Auto Hover enabled", vim.log.levels.INFO, { title = "LSP" })
    else
        vim.notify("Auto Hover disabled", vim.log.levels.INFO, { title = "LSP" })
    end
end

vim.keymap.set(
    "n",
    "<leader><leader>Th",
    toggle_auto_hover,
    { desc = "Toggle LSP auto hover", noremap = false, silent = true }
)
