local M = {}

local lang_cache = {}

local function get_lang(filename)
    if lang_cache[filename] then
        return lang_cache[filename]
    end

    local ft = vim.filetype.match { filename = filename }
    if not ft then
        local ext = vim.fn.fnamemodify(filename, ":e")
        if ext ~= "" then
            ft = ext
        end
    end

    if not ft then
        return nil
    end

    ---@type string|nil
    local lang = vim.treesitter.language.get_lang(ft) or ft
    local has_lang = pcall(vim.treesitter.language.add, lang)
    if not has_lang then
        lang = nil
    end

    lang_cache[filename] = lang
    return lang
end

function M.highlight_entry(buf, ns, line_idx, line, highlight_code)
    local bufnr = line:match "^(%d+): "
    if bufnr then
        vim.api.nvim_buf_set_extmark(buf, ns, line_idx, 0, {
            end_col = #bufnr,
            hl_group = "WarningMsg",
            priority = 100,
        })

        local path_start = #bufnr + 3
        local path_part = line:sub(path_start)
        local dir_str = path_part:match "^(.*/)"
        if dir_str then
            vim.api.nvim_buf_set_extmark(buf, ns, line_idx, path_start - 1, {
                end_col = path_start - 1 + #dir_str,
                hl_group = "Comment",
                priority = 100,
            })
        end
        return
    end

    local suffix_start = line:find ":%d+:%d+"
    local path_end = suffix_start and (suffix_start - 1) or #line
    local path_part = line:sub(1, path_end)

    local dir_str = path_part:match "^(.*/)"
    if dir_str then
        vim.api.nvim_buf_set_extmark(buf, ns, line_idx, 0, {
            end_col = #dir_str,
            hl_group = "Comment",
            priority = 100,
        })
    end

    if suffix_start then
        local s, e = line:find(":%d+:", suffix_start)
        if s then
            vim.api.nvim_buf_set_extmark(buf, ns, line_idx, s, {
                end_col = e - 1,
                hl_group = "String",
                priority = 100,
            })
        end

        if highlight_code then
            local _, coords_end = line:find(":%d+:%d+", suffix_start)
            if coords_end then
                local content_start = line:find(":", coords_end)
                if content_start then
                    local content = line:sub(content_start + 1)
                    M.highlight_code(buf, ns, line_idx, content_start, content, path_part)
                end
            end
        end
    end
end

function M.highlight_code(buf, ns, row, start_col, content, filename)
    local lang = get_lang(filename)
    if not lang then
        return
    end

    local parser = vim.treesitter.get_string_parser(content, lang)
    local tree = parser:parse()[1]
    local root = tree:root()

    local query = vim.treesitter.query.get(lang, "highlights")
    if not query then
        return
    end

    for id, node, _ in query:iter_captures(root, content, 0, -1) do
        local capture_name = query.captures[id]
        local hl_group = "@" .. capture_name

        local _, c1, _, c2 = node:range()

        vim.api.nvim_buf_set_extmark(buf, ns, row, start_col + c1, {
            end_col = start_col + c2,
            hl_group = hl_group,
            priority = 110,
        })
    end
end

return M
