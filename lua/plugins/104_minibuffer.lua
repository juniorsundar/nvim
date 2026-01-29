local M = require "minibuffer"

vim.keymap.set("n", "<A-x>", function()
    M.pick(function(input)
        if input == "" then
            return vim.fn.getcompletion("", "command")
        end
        return vim.fn.getcompletion(input, "cmdline")
    end, function(input_text)
        vim.cmd(input_text)
    end, { prompt = "M-x > " })
end, { desc = "Minibuffer Command Palette" })

local function fetch_references(on_result)
    local clients = vim.lsp.get_clients { bufnr = 0 }
    local client = clients[1]

    if not client then
        print "No LSP client attached"
        return
    end

    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    params.context = { includeDeclaration = true }

    vim.lsp.buf_request(0, "textDocument/references", params, function(err, result, _, _)
        if err then
            print("LSP Error: " .. tostring(err))
            return
        end
        if not result or vim.tbl_isempty(result) then
            print "No references found"
            return
        end

        local items = {}

        for _, loc in ipairs(result) do
            local filename = vim.uri_to_fname(loc.uri)
            local lnum = loc.range.start.line + 1
            local col = loc.range.start.character + 1

            local relative_path = vim.fn.fnamemodify(filename, ":.")
            local entry = string.format("%s:%d:%d", relative_path, lnum, col)
            table.insert(items, entry)
        end

        on_result(items)
    end)
end

vim.keymap.set("n", "<C-x>t", function()
    fetch_references(function(items)
        M.pick(items, function(selection)
            if not selection or selection == "" then
                return
            end

            local filename, lnum, col = selection:match "^(.*):(%d+):(%d+)$"

            if filename and lnum and col then
                vim.cmd("edit " .. filename)
                vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
            end
        end)
    end)
end, { desc = "LSP References via Minibuffer" })

return M
