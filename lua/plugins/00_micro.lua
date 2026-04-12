local pack = require "micro.pack"

require("micro").setup {
    breadcrumbs = { enabled = false },
    dynamic_lnum = { enabled = true },
    folds = { enabled = true },
    hover = { enabled = true },
    pack = { enabled = true },
    session = { enabled = true },
    signature = { enabled = true },
    split_suffix = { enabled = true },
    statusline = {
        enabled = true,
        ignored = {
            names = {
                ["[Lazygit]"] = true,
            },
        },
    },
    toggle = { enabled = true },
    treesit_navigator = { enabled = true },
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

vim.keymap.set("n", "<leader>P", "", { desc = "Package", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Pu", function()
    pack.update()
end, { desc = "Update all plugins" })
vim.keymap.set("n", "<leader>Pc", function()
    pack.clean()
end, { desc = "Clean orphaned plugins" })
vim.keymap.set("n", "<leader>Pr", function()
    pack.rollback()
end, { desc = "Rollback plugins to lockfile" })
vim.keymap.set("n", "<leader>Ph", function()
    pack.health()
end, { desc = "Check plugin health" })

vim.keymap.set("n", "<leader>S", "", { desc = "Session", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Ss", function()
    require("micro.session").save_session()
end, { desc = "Save session" })
vim.keymap.set("n", "<leader>Sl", function()
    require("micro.session").load_session()
end, { desc = "Load session" })
