MiniDeps.later(function()
    MiniDeps.add { source = "stevearc/quicker.nvim" }

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        once = true,
        callback = function()
            require("quicker").setup {
                keys = {
                    {
                        ">",
                        function()
                            require("quicker").expand { before = 2, after = 2, add_to_existing = true }
                        end,
                        desc = "Expand quickfix context",
                    },
                    {
                        "<",
                        function()
                            require("quicker").collapse()
                        end,
                        desc = "Collapse quickfix context",
                    },
                },
            }
        end,
    })
end)
