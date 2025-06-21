return {
    "mfussenegger/nvim-dap",
    enabled = false,
    dependencies = {
        "igorlfs/nvim-dap-view",
    },
    event = "LspAttach",
    config = function()
        local dap = require("dap")

        vim.keymap.set('n', '<leader>LAc', function() dap.continue() end, { desc = "Continue" })
        vim.keymap.set('n', '<leader>LAb', function() dap.toggle_breakpoint() end, { desc = "Toggle Breakpoint" })
        vim.keymap.set('n', '<leader>LAB',
            function() dap.set_breakpoint(nil, nil, vim.fn.input('Breakpoint condition: ')) end,
            { desc = "Set Conditional Breakpoint" })
        vim.keymap.set('n', '<leader>LAp',
            function() dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end,
            { desc = "Set Log Point" })
        vim.keymap.set('n', '<leader>LAr', function() dap.repl.open() end, { desc = "Open REPL" })
        vim.keymap.set('n', '<leader>LAl', function() dap.run_last() end, { desc = "Run Last" })
        vim.keymap.set('n', '<leader>LAo', function() dap.step_over() end, { desc = "Step Over" })
        vim.keymap.set('n', '<leader>LAi', function() dap.step_into() end, { desc = "Step Into" })
        vim.keymap.set('n', '<leader>LAu', function() dap.step_out() end, { desc = "Step Out" })
        vim.keymap.set('n', '<leader>LAt', function() dap.terminate() end, { desc = "Terminate" })


        dap.adapters.codelldb = {
            type = "executable",
            command = "codelldb",

            -- On windows you may have to uncomment this:
            -- detached = false,
        }
        dap.configurations.cpp = {
            {
                name = "Launch file (C++)",
                type = "codelldb", -- Matches the adapter name (mason-nvim-dap handles this)
                request = "launch",
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
                args = {},                   -- Add command line arguments if needed
                sourceLanguages = { "cpp" }, -- Often optional but can help
            },
        }

        -- Use the same structure for C and Rust, just change the name
        dap.configurations.c = {
            {
                name = "Launch file (C)",
                type = "codelldb",
                request = "launch",
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
                args = {},
                sourceLanguages = { "c" },
            },
        }

        -- For Rust, you might want to automatically detect the target binary
        dap.configurations.rust = {
            {
                name = "Launch file (Rust)",
                type = "codelldb",
                request = "launch",
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
                    -- More advanced: could try parsing Cargo.toml or using a helper function
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
                args = {},
                sourceLanguages = { "rust" },
            },
        }
    end
}
