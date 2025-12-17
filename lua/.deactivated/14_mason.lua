local mason_bin = vim.fn.stdpath "data" .. "/mason/bin"
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

MiniDeps.later(function()
    MiniDeps.add { source = "mason-org/mason.nvim" }

    vim.keymap.set("n", "<leader>m", function()
        if not package.loaded["mason"] then
            require("mason").setup()
        end
        require("mason.ui").open()
    end, { desc = "Mason", noremap = false, silent = true })
end)
