local M = {}

local api = vim.api

-- Define highlight groups
local function setup_highlights()
    local hls = {
        GrepFile = { link = "Comment" },
        GrepFileBase = { link = "Normal" },
        GrepLine = { link = "String" },
        GrepCol = { link = "String" },
        GrepSep = { link = "Operator" },
    }
    for group, val in pairs(hls) do
        api.nvim_set_hl(0, group, { link = val.link, default = true })
    end
end

setup_highlights()

local ns_id = api.nvim_create_namespace "buffers_grep_syntax"

-- Table to store metadata: buffer_data[bufnr][line_idx] = { filename, lnum, col }
M.buffer_data = {}

---Parse a grep line
---@param line string
---@return table|nil { filename, lnum, col, text, prefix_str, dir_len }
local function parse_line(line)
    local s_file, e_file, filename = line:find "^([^:]+)"
    if not s_file then
        return nil
    end

    if line:sub(e_file + 1, e_file + 1) ~= ":" then
        return nil
    end

    local s_lnum, e_lnum, lnum = line:find("^(%d+)", e_file + 2)
    if not s_lnum then
        return nil
    end

    if line:sub(e_lnum + 1, e_lnum + 1) ~= ":" then
        return nil
    end

    local s_col, e_col, col = line:find("^(%d+)", e_lnum + 2)
    if not s_col then
        return nil
    end

    if line:sub(e_col + 1, e_col + 1) ~= ":" then
        return nil
    end

    local text_start = e_col + 2
    local text = line:sub(text_start)

    -- Calculate directory length for highlighting in virtual text
    local dir_part = filename:match "^(.*[/\\])"
    local dir_len = dir_part and #dir_part or 0

    -- Construct the prefix string exactly as it appeared
    local prefix_str = line:sub(1, e_col + 1)

    return {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
        prefix_str = prefix_str,
        dir_len = dir_len,
    }
end

---Highlights the buffer using virtual text and treesitter
---TRANSFORMS the buffer content by stripping the prefix
function M.highlight_buffer(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if #lines == 0 then
        return
    end

    local updates = {} -- { {start_row, end_row, replacement_lines} }
    local metadata_updates = {} -- { [row] = meta }
    local needs_update = false

    M.buffer_data[bufnr] = M.buffer_data[bufnr] or {}

    for i, line in ipairs(lines) do
        local parsed = parse_line(line)
        if parsed then
            needs_update = true
            metadata_updates[i - 1] = {
                filename = parsed.filename,
                lnum = parsed.lnum,
                col = parsed.col,
                dir_len = parsed.dir_len,
                prefix_str = parsed.prefix_str,
            }
        end
    end

    if not needs_update then
        M.refresh_virt_text(bufnr)
        return
    end

    -- Apply buffer transformations
    -- We construct a new table of lines
    local new_lines = {}
    for i, line in ipairs(lines) do
        if metadata_updates[i - 1] then
            local parsed = parse_line(line)
            table.insert(new_lines, parsed.text)
            M.buffer_data[bufnr][i - 1] = metadata_updates[i - 1]
        else
            table.insert(new_lines, line)
            M.buffer_data[bufnr][i - 1] = nil
        end
    end

    -- Update buffer content (atomic)
    -- We use pcall to avoid issues if buffer changed
    local ok = pcall(api.nvim_buf_set_lines, bufnr, 0, -1, false, new_lines)
    if not ok then
        return
    end

    -- Now apply virtual text and highlights
    M.refresh_virt_text(bufnr)
end

---Refreshes virtual text and TS highlights based on stored metadata
function M.refresh_virt_text(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local metas = M.buffer_data[bufnr] or {}

    for i, line in ipairs(lines) do
        local row = i - 1
        local meta = metas[row]

        if meta then
            local virt_chunks = {}

            -- Directory
            if meta.dir_len > 0 then
                table.insert(virt_chunks, { meta.filename:sub(1, meta.dir_len), "GrepFile" })
            end

            -- Filename Base
            table.insert(virt_chunks, { meta.filename:sub(meta.dir_len + 1), "GrepFileBase" })

            -- Separator
            table.insert(virt_chunks, { ":", "GrepSep" })

            -- Lnum
            table.insert(virt_chunks, { tostring(meta.lnum), "GrepLine" })

            -- Separator
            table.insert(virt_chunks, { ":", "GrepSep" })

            -- Col
            table.insert(virt_chunks, { tostring(meta.col), "GrepCol" })

            -- Separator
            table.insert(virt_chunks, { ":", "GrepSep" })

            -- Set Extmark with Inline Virtual Text
            api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, {
                virt_text = virt_chunks,
                virt_text_pos = "inline",
                -- virt_text_pos = "overlay", -- Fallback if inline not supported? Inline is best.
                hl_mode = "combine",
            })

            if #line > 0 then
                local ft = vim.filetype.match { filename = meta.filename }
                if ft then
                    local lang = vim.treesitter.language.get_lang(ft)
                    if lang then
                        local parser_passed, parser = pcall(vim.treesitter.get_string_parser, line, lang)
                        if parser_passed and parser then
                            local tree_passed, tree = pcall(function()
                                return parser:parse()[1]
                            end)
                            if tree_passed and tree then
                                local query = vim.treesitter.query.get(lang, "highlights")
                                if query then
                                    for id, node, _ in query:iter_captures(tree:root(), line, 0, -1) do
                                        local name = query.captures[id]
                                        local hl_group = "@" .. name .. "." .. lang
                                        local _, s_col, _, e_col = node:range()

                                        api.nvim_buf_set_extmark(bufnr, ns_id, row, s_col, {
                                            end_col = e_col,
                                            hl_group = hl_group,
                                            priority = 100,
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

---Navigates to the location using stored metadata
function M.nav_to_match()
    local bufnr = api.nvim_get_current_buf()
    local row = api.nvim_win_get_cursor(0)[1] - 1

    local metas = M.buffer_data[bufnr]
    if not metas then
        vim.notify("No metadata found for this buffer", vim.log.levels.WARN)
        return
    end

    local meta = metas[row]
    if not meta then
        vim.notify("Not a valid grep result", vim.log.levels.WARN)
        return
    end

    if vim.fn.filereadable(meta.filename) == 0 then
        vim.notify("File not found: " .. meta.filename, vim.log.levels.ERROR)
        return
    end

    vim.cmd.edit(meta.filename)

    pcall(api.nvim_win_set_cursor, 0, { meta.lnum, meta.col - 1 })
    vim.cmd "normal! zz"
end

---Creates a new grep buffer with the provided lines
---@param lines string[]
function M.create_buffer(lines)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "grep"
    vim.cmd.buffer(buf)
end

return M
