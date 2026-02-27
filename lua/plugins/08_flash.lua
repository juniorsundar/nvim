MiniDeps.add { source = "folke/flash.nvim" }

require("flash").setup()
local is_vscode = vim.g.vscode
local jump_key = is_vscode and "<leader>s" or "<C-s>"
local treesitter_key = is_vscode and "<leader>S" or "<C-M-s>"
local incremental_key = is_vscode and "<leader>v" or "<c-space>"
local incremental_actions = is_vscode and {
    ["n"] = "next",
    ["p"] = "prev",
} or {
    ["<c-space>"] = "next",
    ["<BS>"] = "prev",
}

vim.keymap.set({ "n", "x", "o" }, jump_key, function()
    require("flash").jump()
end, { desc = "Flash", noremap = false, silent = true })
vim.keymap.set({ "n", "x", "o" }, treesitter_key, function()
    require("flash").treesitter()
end, { desc = "Flash Treesitter", noremap = false, silent = true })
vim.keymap.set("o", "gr", function()
    require("flash").remote()
end, { desc = "Remote Flash", noremap = false, silent = true })
vim.keymap.set({ "o", "x" }, "gR", function()
    require("flash").treesitter_search()
end, { desc = "Treesitter Search", noremap = false, silent = true })
vim.keymap.set({ "n", "x", "o" }, incremental_key, function()
    require("flash").treesitter {
        actions = incremental_actions,
    }
end, { desc = "Treesitter incremental selection", noremap = false, silent = true })
