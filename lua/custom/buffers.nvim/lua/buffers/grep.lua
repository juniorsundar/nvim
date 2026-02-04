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

-- Table to store metadata: buffer_data[bufnr][extmark_id] = { filename, lnum, col, original_text }
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

    local dir_part = filename:match "^(.*[/\\])"
    local dir_len = dir_part and #dir_part or 0

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
---TRANSFORMS the buffer content by stripping the prefix if present
function M.highlight_buffer(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    -- If already processed, just refresh highlights and exit
    if vim.b[bufnr].grep_processed then
        M.refresh_virt_text(bufnr)
        return
    end

    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if #lines == 0 then
        return
    end

    M.buffer_data[bufnr] = M.buffer_data[bufnr] or {}

    -- Check if we need to transform (look for raw format in first few lines)
    local needs_transform = false
    -- Scan deeper (e.g. 50 lines) to account for possible headers
    for i = 1, math.min(#lines, 50) do
        if parse_line(lines[i]) then
            needs_transform = true
            break
        end
    end

    if needs_transform then
        vim.b[bufnr].grep_processed = true

        local header = {
            "# GREP EDIT BUFFER",
            "# ------------------",
            "# <CR>        -> Jump to match",
            "# <C-c><C-c>  -> Apply edits (Direct)",
            "# <C-c><C-s>  -> Apply edits (Conflict Markers)",
            "",
        }

        local new_lines = vim.deepcopy(header)
        local metas = {} -- Temporary storage ordered by index
        local header_offset = #header

        -- Clear existing data for this buffer if we are re-parsing
        M.buffer_data[bufnr] = {}
        api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

        for i, line in ipairs(lines) do
            local parsed = parse_line(line)
            if parsed then
                table.insert(new_lines, parsed.text)
                table.insert(metas, {
                    filename = parsed.filename,
                    lnum = parsed.lnum,
                    col = parsed.col,
                    original_text = parsed.text,
                    dir_len = parsed.dir_len,
                    prefix_str = parsed.prefix_str,
                })
            else
                -- Don't preserve lines that don't parse (unless they aren't header lines?)
                -- If we are transforming, we assume input is raw grep output.
                -- Grep output might have garbage, let's keep it.
                table.insert(new_lines, line)
                table.insert(metas, nil)
            end
        end

        -- Update buffer content
        api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)

        -- Create Extmarks and store metadata
        for i, meta in ipairs(metas) do
            if meta then
                -- Row index is i-1 (from iteration) + header_offset
                local row = (i - 1) + header_offset
                local id = api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, {})
                M.buffer_data[bufnr][id] = meta
            end
        end
    end

    M.refresh_virt_text(bufnr)
end

---Refreshes virtual text and TS highlights based on stored metadata (via extmarks)
function M.refresh_virt_text(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    local extmarks = api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, { details = true })
    local buf_data = M.buffer_data[bufnr] or {}

    for _, extmark in ipairs(extmarks) do
        local id = extmark[1]
        local row = extmark[2]
        local col = extmark[3]

        local meta = buf_data[id]
        if meta then
            local virt_chunks = {}
            if meta.dir_len > 0 then
                table.insert(virt_chunks, { meta.filename:sub(1, meta.dir_len), "GrepFile" })
            end
            table.insert(virt_chunks, { meta.filename:sub(meta.dir_len + 1), "GrepFileBase" })
            table.insert(virt_chunks, { ":", "GrepSep" })
            table.insert(virt_chunks, { tostring(meta.lnum), "GrepLine" })
            table.insert(virt_chunks, { ":", "GrepSep" })
            table.insert(virt_chunks, { tostring(meta.col), "GrepCol" })
            table.insert(virt_chunks, { ":", "GrepSep" })

            api.nvim_buf_set_extmark(bufnr, ns_id, row, col, {
                id = id, -- Keep same ID
                virt_text = virt_chunks,
                virt_text_pos = "inline",
                hl_mode = "combine",
            })
        end
    end

    M.refresh_syntax(bufnr)
end

local syntax_ns_id = api.nvim_create_namespace "buffers_grep_syntax_highlight"

function M.refresh_syntax(bufnr)
    api.nvim_buf_clear_namespace(bufnr, syntax_ns_id, 0, -1)

    local extmarks = api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {})
    local buf_data = M.buffer_data[bufnr] or {}

    for _, extmark in ipairs(extmarks) do
        local id = extmark[1]
        local row = extmark[2]

        local meta = buf_data[id]
        if meta then
            local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
            if line and #line > 0 then
                local ft = vim.filetype.match { filename = meta.filename }
                if ft then
                    local lang = vim.treesitter.language.get_lang(ft)
                    if lang then
                        local ok, parser = pcall(vim.treesitter.get_string_parser, line, lang)
                        if ok and parser then
                            local ok_tree, tree = pcall(function()
                                return parser:parse()[1]
                            end)
                            if ok_tree and tree then
                                local query = vim.treesitter.query.get(lang, "highlights")
                                if query then
                                    for capture_id, node, _ in query:iter_captures(tree:root(), line, 0, -1) do
                                        local name = query.captures[capture_id]
                                        local hl_group = "@" .. name .. "." .. lang
                                        local _, s_col, _, e_col = node:range()

                                        api.nvim_buf_set_extmark(bufnr, syntax_ns_id, row, s_col, {
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

---Navigates to the location under cursor
function M.nav_to_match()
    local bufnr = api.nvim_get_current_buf()
    local row = api.nvim_win_get_cursor(0)[1] - 1

    local extmarks = api.nvim_buf_get_extmarks(bufnr, ns_id, { row, 0 }, { row, -1 }, { limit = 1 })
    if #extmarks == 0 then
        vim.notify("No grep result on this line", vim.log.levels.WARN)
        return
    end

    local id = extmarks[1][1]
    local meta = M.buffer_data[bufnr][id]

    if not meta then
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

---Creates a new grep buffer
function M.create_buffer(lines)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "grep"
    vim.cmd.buffer(buf)
end

---Apply edits to files
---@param mode "direct"|"conflict"
function M.apply_edits(mode)
    local bufnr = api.nvim_get_current_buf()
    local buf_data = M.buffer_data[bufnr]
    if not buf_data then
        return
    end

    local extmarks = api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, { details = true })

    local file_edits = {}

    for _, extmark in ipairs(extmarks) do
        local id = extmark[1]
        local row = extmark[2]
        local meta = buf_data[id]

        if meta then
            local current_text = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
            if current_text and current_text ~= meta.original_text then
                file_edits[meta.filename] = file_edits[meta.filename] or {}
                table.insert(file_edits[meta.filename], {
                    lnum = meta.lnum,
                    original = meta.original_text,
                    new = current_text,
                })
            end
        end
    end

    for filename, edits in pairs(file_edits) do
        table.sort(edits, function(a, b)
            return a.lnum > b.lnum
        end)

        local file_lines = {}
        if vim.fn.filereadable(filename) == 1 then
            file_lines = vim.fn.readfile(filename)
        else
            vim.notify("File missing: " .. filename, vim.log.levels.ERROR)
            goto continue
        end

        local modified_count = 0

        for _, edit in ipairs(edits) do
            local idx = edit.lnum

            local file_content = file_lines[idx]
            if not file_content or not file_content:find(edit.original, 1, true) then
                vim.notify(string.format("Conflict in %s:%d. Skipping.", filename, idx), vim.log.levels.WARN)
            else
                if mode == "direct" then
                    file_lines[idx] = edit.new
                elseif mode == "conflict" then
                    local conflict_block = {
                        "<<<<<<< LOCAL",
                        file_lines[idx],
                        "=======",
                        edit.new,
                        ">>>>>>> REMOTE",
                    }
                    table.remove(file_lines, idx)
                    for k = #conflict_block, 1, -1 do
                        table.insert(file_lines, idx, conflict_block[k])
                    end
                end
                modified_count = modified_count + 1
            end
        end

        if modified_count > 0 then
            vim.fn.writefile(file_lines, filename)
            vim.notify(string.format("Applied %d changes to %s", modified_count, filename))
        end

        ::continue::
    end
end

return M
