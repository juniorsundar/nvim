local function smart_conceal(text, params, active_idx, max_width)
    if not params or #params == 0 or #text <= max_width then
        return text
    end

    local parsed_params = {}
    for i, p in ipairs(params) do
        local p_start, p_end
        if type(p.label) == "table" then
            p_start, p_end = p.label[1] + 1, p.label[2]
        elseif type(p.label) == "string" then
            p_start, p_end = string.find(text, p.label, 1, true)
        end
        if p_start and p_end then
            table.insert(parsed_params, { start = p_start, finish = p_end, index = i })
        end
    end

    local concealed = {}
    local current_len = #text

    while current_len > max_width do
        local furthest_idx = -1
        local max_dist = -1

        for i = 1, #parsed_params do
            if not concealed[i] and i ~= active_idx then
                local dist = math.abs(i - active_idx)
                if dist > max_dist then
                    max_dist = dist
                    furthest_idx = i
                end
            end
        end

        if furthest_idx == -1 then
            break
        end

        concealed[furthest_idx] = true
        local p_len = parsed_params[furthest_idx].finish - parsed_params[furthest_idx].start + 1
        current_len = current_len - p_len + 3
    end

    local new_text = ""
    local last_pos = 1

    for i, p in ipairs(parsed_params) do
        if concealed[i] then
            new_text = new_text .. text:sub(last_pos, p.start - 1) .. "..."
            last_pos = p.finish + 1
        end
    end
    new_text = new_text .. text:sub(last_pos)

    return new_text
end

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

        local active_param_idx = signature.activeParameter or result.activeParameter or 0

        local max_width = vim.v.echospace - 2
        local text = smart_conceal(signature.label, signature.parameters, active_param_idx, max_width)

        local param = signature.parameters and signature.parameters[active_param_idx + 1]
        local param_start, param_end = nil, nil

        if param then
            local label_str = param.label
            if type(param.label) == "table" then
                label_str = signature.label:sub(param.label[1] + 1, param.label[2])
            end

            if label_str then
                param_start, param_end = string.find(text, label_str, 1, true)
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
        local current_hl = nil

        for i = 1, #text do
            local char = text:sub(i, i)
            local base_hl = hl_map[i] or "Normal"
            local is_active = param_start and param_end and i >= param_start and i <= param_end

            local hl_val = base_hl
            if is_active then
                hl_val = base_hl .. "ActiveUnderline"
                local hl_info = vim.api.nvim_get_hl(0, { name = base_hl, link = false })
                hl_info.underline = true
                hl_info.default = true
                ---@diagnostic disable-next-line: param-type-mismatch
                vim.api.nvim_set_hl(0, hl_val, hl_info)
            end

            if hl_val == current_hl then
                current_text = current_text .. char
            else
                if current_text ~= "" then
                    table.insert(chunks, { current_text, current_hl })
                end
                current_text = char
                current_hl = hl_val
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
