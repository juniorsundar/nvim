MiniDeps.now(function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    MiniDeps.add { source = "nvim-tree/nvim-tree.lua" }

    require("nvim-tree").setup {
        view = {
            side = "right",
        },
        update_focused_file = {
            enable = true,
            update_root = false,
        },
    }
    vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { link = "Visual" })
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Explorer" })
end)
