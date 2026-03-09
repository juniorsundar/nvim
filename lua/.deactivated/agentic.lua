MiniDeps.later(function()
    MiniDeps.add { source = "carlos-algms/agentic.nvim" }

    require("agentic").setup {
        provider = "opencode-acp",
    }

    vim.keymap.set({ "n", "v", "i" }, "<C-\\>", function()
        require("agentic").toggle()
    end, { desc = "Toggle Agentic Chat" })

    vim.keymap.set({ "n", "v" }, "<C-'>", function()
        require("agentic").add_selection_or_file_to_context()
    end, { desc = "Add file or selection to Agentic to Context" })

    vim.keymap.set({ "n", "v", "i" }, "<C-,>", function()
        require("agentic").new_session()
    end, { desc = "New Agentic Session" })

    vim.keymap.set({ "n", "v", "i" }, "<A-i>r", function()
        require("agentic").restore_session()
    end, { desc = "Agentic Restore session", silent = true })

    vim.keymap.set({ "n" }, "<leader>ad", function()
        require("agentic").add_current_line_diagnostics()
    end, { desc = "Add current line diagnostic to Agentic" })

    vim.keymap.set({ "n" }, "<leader>aD", function()
        require("agentic").add_buffer_diagnostics()
    end, { desc = "Add all buffer diagnostics to Agentic" })
end)
