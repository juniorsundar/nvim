local function print_signature_help()
    local params = vim.lsp.util.make_position_params(0, "utf-8")
    local bufnr = vim.api.nvim_get_current_buf()

    vim.lsp.buf_request(bufnr, "textDocument/signatureHelp", params, function(err, result, ctx, config)
        if err or not result or not result.signatures or #result.signatures == 0 then
            vim.api.nvim_echo({}, false, {})
            return
        end

        local active_idx = (result.activeSignature or 0) + 1
        local signature = result.signatures[active_idx] or result.signatures[1]
        local text = signature.label

        local active_param_idx = signature.activeParameter or result.activeParameter or 0
        local param = signature.parameters and signature.parameters[active_param_idx + 1]
        local param_start, param_end = nil, nil

        if param then
            if type(param.label) == "table" then
                param_start = param.label[1] + 1
                param_end = param.label[2]
            elseif type(param.label) == "string" then
                param_start, param_end = string.find(text, param.label, 1, true)
            end
        end

        local ft = vim.bo[bufnr].filetype
        local lang = vim.treesitter.language.get_lang(ft) or ft

        if lang == "lua" then
            lang = "luau"
        end

        local ok, parser = pcall(vim.treesitter.get_string_parser, text, lang)
        if not ok then
            print(text)
            return
        end

        local query = vim.treesitter.query.get(lang, "highlights")
        if not query then
            print(text)
            return
        end

        local tree = parser:parse()[1]
        local root = tree:root()

        local hl_map = {}
        for id, node in query:iter_captures(root, text) do
            local _, start_col, _, end_col = node:range()
            local hl_group = "@" .. query.captures[id]

            for i = start_col + 1, end_col do
                hl_map[i] = hl_group
            end
        end

        local chunks = {}
        local current_text = ""
        local current_hl = hl_map[1]

        if param_start and param_end and 1 >= param_start and 1 <= param_end then
            current_hl = "LspSignatureActiveParameter"
        end

        for i = 1, #text do
            local char = text:sub(i, i)
            local hl = hl_map[i]

            if param_start and param_end and i >= param_start and i <= param_end then
                hl = "LspSignatureActiveParameter"
            end

            if hl == current_hl then
                current_text = current_text .. char
            else
                if current_text ~= "" then
                    table.insert(chunks, { current_text, current_hl })
                end
                current_text = char
                current_hl = hl
            end
        end

        if current_text ~= "" then
            table.insert(chunks, { current_text, current_hl })
        end

        vim.api.nvim_echo(chunks, false, {})
    end)
end

local timer = nil
local function debounced_signature()
    if timer then
        timer:stop()
        timer:close()
    end

    timer = vim.uv.new_timer()
    if timer == nil then
        return
    end
    timer:start(
        300,
        0,
        vim.schedule_wrap(function()
            local clients = vim.lsp.get_clients { bufnr = 0 }
            if #clients > 0 then
                print_signature_help()
            end
        end)
    )
end

local augroup = vim.api.nvim_create_augroup("AutoSignatureHelp", { clear = true })

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = augroup,
    callback = debounced_signature,
    desc = "Print signature help automatically with debounce",
})

vim.api.nvim_create_user_command("PrintSignatureHelp", print_signature_help, {})
vim.keymap.set("n", "<leader>Ls", print_signature_help, { desc = "Signature" })
