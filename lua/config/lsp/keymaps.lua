local function lsp_function(handler)
    local params = vim.lsp.util.make_position_params(0, "utf-32")
    vim.lsp.buf_request(0, "textDocument/" .. handler, params, function(err, result, _, _)
        if err or not result or vim.tbl_isempty(result) then
            return
        end

        if #result > 1 then
            vim.cmd("lua Snacks.picker.lsp_" .. handler .. "s()")
        else
            local win_width = vim.o.columns
            local threshold = 120
            if win_width > threshold then
                vim.cmd("vsplit | lua vim.lsp.buf." .. handler .. "()")
            else
                vim.cmd("split | lua vim.lsp.buf." .. handler .. "()")
            end
        end
    end)
end

vim.keymap.set("n", "<leader>L", "", { desc = "LSP", noremap = false, silent = true })
vim.keymap.set("n", "<leader>LD", "", { desc = "Document", noremap = false, silent = true })
vim.keymap.set("n", "<leader>LW", "", { desc = "Workspace", noremap = false, silent = true })

vim.keymap.set("n", "<leader>LI", function() vim.cmd [[checkhealth lsp]] end,
    { desc = "LSP Info", noremap = false, silent = true })
vim.keymap.set("n", "<leader>La", function() vim.lsp.buf.code_action() end,
    { desc = "Code Action", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Lf", function() vim.lsp.buf.format() end,
    { desc = "Format", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Ll", function() vim.lsp.codelens.run() end,
    { desc = "CodeLens Action", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Ln", function() vim.lsp.buf.rename() end,
    { desc = "Rename", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Lk", function() vim.lsp.buf.hover { border = "rounded" } end,
    { desc = "Hover", noremap = false, silent = true })
vim.keymap.set("n", "<leader>LWa", function() vim.lsp.buf.add_workspace_folder() end,
    { desc = "Add Workspace Folder", noremap = false, silent = true })
vim.keymap.set("n", "<leader>LWr", function() vim.lsp.buf.remove_workspace_folder() end,
    { desc = "Remove Workspace Folder", noremap = false, silent = true })
vim.keymap.set("n", "<leader>LWl", function() vim.lsp.buf.list_workspace_folders() end,
    { desc = "List Workspace Folders", noremap = false, silent = true })
vim.keymap.set("n", "<leader>LWs", function() Snacks.picker.lsp_workspace_symbols() end,
    { desc = "Workspace Symbols", noremap = false, silent = true })
vim.keymap.set("n", "<leader>LWd", function() Snacks.picker.diagnostics() end,
    { desc = "Workspace Diagnostics", noremap = false, silent = true })
vim.keymap.set("n", "<leader>LDs", function() Snacks.picker.lsp_symbols() end,
    { desc = "Document Symbols", noremap = false, silent = true })
vim.keymap.set("n", "<leader>LDd", function() Snacks.picker.diagnostics_buffer() end,
    { desc = "Document Diagnostics", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Ld", function() lsp_function "definition" end,
    { desc = "Definition", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Lc", function() lsp_function "declaration" end,
    { desc = "Declaration", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Li", function() lsp_function "implementation" end,
    { desc = "Implementation", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Lr", function() Snacks.picker.lsp_references() end,
    { desc = "References", noremap = false, silent = true })
vim.keymap.set("n", "<leader>Lt", function() Snacks.picker.lsp_type_definitions() end,
    { desc = "Type Definition", noremap = false, silent = true })
