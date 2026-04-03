require("micro").setup {
    statusline = {
        enabled = true,
        ignored = {
            names = {
                ["[Lazygit]"] = true,
            },
        },
    },
    dynamic_lnum = { enabled = true },
    treesit_navigator = { enabled = true },
    breadcrumbs = { enabled = false },
    toggle = { enabled = true },
    folds = { enabled = true },
    hover = { enabled = true },
    signature = { enabled = true },
    split_suffix = { enabled = true },
}

vim.keymap.set("n", "<leader>Lk", function()
    vim.Micro.eldoc()
end, { desc = "Hover", noremap = false, silent = true })
vim.keymap.set("n", "<M-j>", function()
    require("micro.hover").scroll(1)
end, { desc = "Scroll eldoc down" })
vim.keymap.set("n", "<M-k>", function()
    require("micro.hover").scroll(-1)
end, { desc = "Scroll eldoc up" })

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "screen.txt",
    callback = function(context)
        vim.api.nvim_open_term(context.buf, {})
        vim.keymap.set("n", "q", "<cmd>qa!<cr>", { silent = true, buffer = context.buf })
        vim.cmd "normal! G$"
    end,
})
