MiniDeps.later(function()
    MiniDeps.add({ source = "stevearc/oil.nvim" })

    vim.keymap.set("n", "<leader>o", function()
        if not package.loaded["oil"] then
            require("oil").setup({
                columns = {
                    "permissions",
                    "mtime",
                    "size",
                    "icon",
                },
                view_options = {
                    show_hidden = true,
                },
                confirmation = {
                    border = "rounded"
                }
            })
        end

        vim.cmd("Oil")
    end, { desc = "Oil", noremap = false, silent = true })
end)
