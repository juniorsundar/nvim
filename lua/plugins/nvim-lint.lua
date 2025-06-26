return {
    'mfussenegger/nvim-lint',
    enabled = true,
    event = "LspAttach",
    config = function()
        require('lint').linters_by_ft = {
            rust = { 'clippy' },
        }
        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
            callback = function()
                require("lint").try_lint()
            end,
        })
    end
}
