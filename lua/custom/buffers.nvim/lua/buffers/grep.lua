local M = {}

local api = vim.api
local EXPAND_STEP = 3
local HEADER_LINES = 10
local HEADER_TEXT = {
    "# GREP EDIT BUFFER",
    "# ------------------",
    "# <CR>        -> Jump to shown line",
    "# <Tab>       -> Expand context (+3 each side)",
    "# <S-Tab>     -> Collapse context",
    "# <C-c><C-c>  -> Apply edits (Direct)",
    "# <C-c><C-s>  -> Apply edits (Conflict Markers)",
    "# <C-c><C-r>  -> Refresh content from disk",
    "# q           -> Kill buffer",
    "",
}
assert(#HEADER_TEXT == HEADER_LINES, "header line count mismatch")

--- Set during programmatic line-count changes so the structural-edit
--- guard does not treat them as user edits.
M._programmatic = {}

--- Expected buffer line count, kept in sync by refresh_views and
--- highlight_buffer. The guard compares the live count against this.
M.expected_line_count = {}

local function setup_highlights()
    local hls = {
        GrepFile = { link = "Comment" },
        GrepFileBase = { link = "Normal" },
        GrepLine = { link = "String" },
        GrepCol = { link = "String" },
        GrepSep = { link = "Operator" },
        GrepContextHeader = { link = "Title" },
        GrepContextBorder = { link = "Comment" },
        GrepContextSign = { link = "Visual" },
    }
    for group, val in pairs(hls) do
        api.nvim_set_hl(0, group, { link = val.link, default = true })
    end
end

setup_highlights()

local ns_id = api.nvim_create_namespace "buffers_grep_syntax"
local frame_ns_id = api.nvim_create_namespace "buffers_grep_context_headers"
local syntax_ns_id = api.nvim_create_namespace "buffers_grep_syntax_highlight"
local visual_ns_id = api.nvim_create_namespace "buffers_grep_context_visual"

-- buffer_data[bufnr][extmark_id] stores metadata for each original grep match.
M.buffer_data = {}
M.row_index = {}

local function parse_line(line)
    local s_file, e_file, filename = line:find "^([^:]+)"
    if not s_file or line:sub(e_file + 1, e_file + 1) ~= ":" then
        return nil
    end

    local s_lnum, e_lnum, lnum = line:find("^(%d+)", e_file + 2)
    if not s_lnum or line:sub(e_lnum + 1, e_lnum + 1) ~= ":" then
        return nil
    end

    local s_col, e_col, col = line:find("^(%d+)", e_lnum + 2)
    if not s_col or line:sub(e_col + 1, e_col + 1) ~= ":" then
        return nil
    end

    local dir_part = filename:match "^(.*[/\\])"
    local dir_len = dir_part and #dir_part or 0
    return {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = line:sub(e_col + 2),
        prefix_str = line:sub(1, e_col + 1),
        dir_len = dir_len,
    }
end

local function match_extmarks(bufnr)
    local extmarks = {}
    for id, meta in pairs(M.buffer_data[bufnr] or {}) do
        table.insert(extmarks, { id, meta.buffer_row, 0 })
    end
    table.sort(extmarks, function(a, b)
        return a[2] < b[2]
    end)
    return extmarks
end

local function match_row(bufnr, id)
    local meta = M.buffer_data[bufnr] and M.buffer_data[bufnr][id]
    return meta and meta.buffer_row
end

local function context_row(_, entry)
    return entry.buffer_row
end

-- Context and match row metadata deliberately remains independent of extmark
-- gravity, so replacing a whole line through the public buffer API is stable.
local function shift_rows(bufnr, start_row, delta)
    for _, meta in pairs(M.buffer_data[bufnr] or {}) do
        if meta.buffer_row >= start_row then
            meta.buffer_row = meta.buffer_row + delta
        end
        for _, entry in ipairs(meta.context or {}) do
            if entry.buffer_row >= start_row then
                entry.buffer_row = entry.buffer_row + delta
            end
        end
    end
end

local function filename_chunks(meta)
    local chunks = {}
    if meta.dir_len > 0 then
        table.insert(chunks, { meta.filename:sub(1, meta.dir_len), "GrepFile" })
    end
    table.insert(chunks, { meta.filename:sub(meta.dir_len + 1), "GrepFileBase" })
    return chunks
end

---Rebuild the public row lookup. A physical row can belong to several
---expanded match windows, but has one selected owner for cursor operations.
function M.rebuild_row_index(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local index = {}
    local data = M.buffer_data[bufnr] or {}

    local function add_member(row, member)
        index[row] = index[row] or { members = {} }
        table.insert(index[row].members, member)
    end

    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local id, row = extmark[1], extmark[2]
        local meta = data[id]
        if meta then
            add_member(row, { match_id = id, kind = "match", lnum = meta.lnum })
            for context_index, entry in ipairs(meta.context or {}) do
                add_member(entry.buffer_row, {
                    match_id = id,
                    kind = "context",
                    context_index = context_index,
                    lnum = entry.lnum,
                })
            end
        end
    end

    for _, location in pairs(index) do
        table.sort(location.members, function(a, b)
            local a_meta, b_meta = data[a.match_id], data[b.match_id]
            local a_distance = math.abs(a.lnum - a_meta.lnum)
            local b_distance = math.abs(b.lnum - b_meta.lnum)
            if a_distance ~= b_distance then
                return a_distance < b_distance
            end
            if a_meta.lnum ~= b_meta.lnum then
                return a_meta.lnum < b_meta.lnum
            end
            return a.match_id < b.match_id
        end)
        local selected = location.members[1]
        location.match_id = selected.match_id
        location.kind = selected.kind
        location.context_index = selected.context_index
    end
    M.row_index[bufnr] = index
    return index
end

---Return source metadata for a zero-based grep buffer row.
---@return table|nil location { meta, entry|nil, kind, match_id }
function M.line_at_row(bufnr, row)
    bufnr = bufnr or api.nvim_get_current_buf()
    local index = M.row_index[bufnr] or M.rebuild_row_index(bufnr)
    local location = index[row]
    if not location then
        return nil
    end

    local meta = M.buffer_data[bufnr] and M.buffer_data[bufnr][location.match_id]
    if not meta then
        return nil
    end
    return {
        meta = meta,
        entry = location.kind == "context" and meta.context[location.context_index] or nil,
        kind = location.kind,
        match_id = location.match_id,
    }
end

local function shown_source_rows(bufnr)
    local rows, by_key = {}, {}

    -- First pass: add every match anchor. Match anchors are NEVER
    -- deduped — each grep match is a distinct anchor with its own
    -- extmark and buffer_row, even if they share filename:lnum.
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local id = extmark[1]
        local meta = M.buffer_data[bufnr][id]
        if meta then
            local key = meta.filename .. "\0" .. meta.lnum
            by_key[key] = true
            table.insert(rows, {
                filename = meta.filename,
                lnum = meta.lnum,
                row = meta.buffer_row,
                meta = meta,
                match_id = id,
                kind = "match",
            })
        end
    end

    -- Second pass: add context rows, deduped by filename:lnum against
    -- match anchors and other context rows. A context row whose
    -- filename:lnum is already shown (by a match anchor or another
    -- context row) is skipped.
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local meta = M.buffer_data[bufnr][extmark[1]]
        if meta then
            for _, entry in ipairs(meta.context or {}) do
                local key = meta.filename .. "\0" .. entry.lnum
                if not by_key[key] then
                    by_key[key] = true
                    table.insert(rows, {
                        filename = meta.filename,
                        lnum = entry.lnum,
                        row = entry.buffer_row,
                        meta = meta,
                        kind = "context",
                    })
                end
            end
        end
    end

    return rows
end

local function expanded_regions(bufnr)
    local by_file = {}
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local meta = M.buffer_data[bufnr][extmark[1]]
        if meta and #(meta.context or {}) > 0 then
            local first, last = meta.lnum, meta.lnum
            for _, entry in ipairs(meta.context) do
                first = math.min(first, entry.lnum)
                last = math.max(last, entry.lnum)
            end
            by_file[meta.filename] = by_file[meta.filename] or {}
            table.insert(by_file[meta.filename], { first = first, last = last, meta = meta })
        end
    end

    local regions = {}
    for filename, windows in pairs(by_file) do
        table.sort(windows, function(a, b)
            return a.first < b.first
        end)
        local region
        for _, window in ipairs(windows) do
            if not region or window.first > region.last + 1 then
                region = { filename = filename, first = window.first, last = window.last, meta = window.meta }
                table.insert(regions, region)
            else
                region.last = math.max(region.last, window.last)
            end
        end
    end
    return regions
end

local function render_frames(bufnr)
    api.nvim_buf_clear_namespace(bufnr, frame_ns_id, 0, -1)
    local source_rows = shown_source_rows(bufnr)
    for _, region in ipairs(expanded_regions(bufnr)) do
        local displayed = {}
        for _, source in ipairs(source_rows) do
            if source.filename == region.filename and source.lnum >= region.first and source.lnum <= region.last then
                table.insert(displayed, source)
            end
        end
        table.sort(displayed, function(a, b)
            return a.lnum < b.lnum
        end)
        if #displayed > 0 then
            local header = { { "┌─ ", "GrepContextBorder" } }
            for _, chunk in ipairs(filename_chunks(region.meta)) do
                table.insert(header, { chunk[1], "GrepContextHeader" })
            end
            local bottom_width = 83
            local top_fixed = 3 + #region.meta.filename + 1 -- "┌─ " + filename + " "
            local dash_count = math.max(1, bottom_width - top_fixed)
            table.insert(header, { " " .. string.rep("─", dash_count), "GrepContextBorder" })
            api.nvim_buf_set_extmark(bufnr, frame_ns_id, displayed[1].row, 0, {
                virt_lines = { header },
                virt_lines_above = true,
                virt_lines_leftcol = true,
            })
            api.nvim_buf_set_extmark(bufnr, frame_ns_id, displayed[#displayed].row, 0, {
                virt_lines = { { { "└" .. string.rep("─", 82), "GrepContextBorder" } } },
                virt_lines_leftcol = true,
            })
            for _, source in ipairs(displayed) do
                api.nvim_buf_set_extmark(bufnr, frame_ns_id, source.row, 0, {
                    sign_text = " ",
                    sign_hl_group = "GrepContextSign",
                    priority = 100,
                })
            end
        end
    end
end

local function refresh_views(bufnr)
    M.rebuild_row_index(bufnr)
    render_frames(bufnr)
    M.refresh_virt_text(bufnr)
    M.expected_line_count[bufnr] = HEADER_LINES + #shown_source_rows(bufnr)
    M._programmatic[bufnr] = false
end

---Highlights the buffer using virtual text and transforms raw grep lines once.
function M.highlight_buffer(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    if vim.b[bufnr].grep_processed then
        M.refresh_virt_text(bufnr)
        return
    end

    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if #lines == 0 then
        return
    end

    local needs_transform = false
    for i = 1, math.min(#lines, 50) do
        if parse_line(lines[i]) then
            needs_transform = true
            break
        end
    end
    if not needs_transform then
        return
    end

    vim.b[bufnr].grep_processed = true
    M._programmatic[bufnr] = true
    local header = HEADER_TEXT

    local new_lines, metas = vim.deepcopy(header), {}
    M.buffer_data[bufnr] = {}
    M.row_index[bufnr] = {}
    api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    api.nvim_buf_clear_namespace(bufnr, frame_ns_id, 0, -1)
    api.nvim_buf_clear_namespace(bufnr, visual_ns_id, 0, -1)

    for _, line in ipairs(lines) do
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
                context = {},
                expand_up = 0,
                expand_down = 0,
            })
        else
            table.insert(new_lines, line)
            table.insert(metas, nil)
        end
    end

    api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
    for i, meta in ipairs(metas) do
        if meta then
            local id = api.nvim_buf_set_extmark(bufnr, ns_id, HEADER_LINES + i - 1, 0, {})
            meta.buffer_row = HEADER_LINES + i - 1
            M.buffer_data[bufnr][id] = meta
        end
    end
    refresh_views(bufnr)
    M._setup_guard(bufnr)
end

---Refreshes virtual text, match emphasis, and Treesitter highlights.
function M.refresh_virt_text(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    api.nvim_buf_clear_namespace(bufnr, visual_ns_id, 0, -1)
    local buf_data = M.buffer_data[bufnr] or {}
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local id, row, col = extmark[1], extmark[2], extmark[3]
        local meta = buf_data[id]
        if meta then
            local expanded = #(meta.context or {}) > 0
            if expanded then
                -- Updating the anchored extmark with empty text explicitly clears
                -- a prefix that may have been rendered while this match was collapsed.
                api.nvim_buf_set_extmark(bufnr, ns_id, row, col, { id = id, virt_text = {} })
            else
                local chunks = filename_chunks(meta)
                table.insert(chunks, { ":", "GrepSep" })
                table.insert(chunks, { tostring(meta.lnum), "GrepLine" })
                table.insert(chunks, { ":", "GrepSep" })
                table.insert(chunks, { tostring(meta.col), "GrepCol" })
                table.insert(chunks, { ":", "GrepSep" })
                api.nvim_buf_set_extmark(bufnr, ns_id, row, col, {
                    id = id,
                    virt_text = chunks,
                    virt_text_pos = "inline",
                    hl_mode = "combine",
                })
            end

            if expanded then
                local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
                if line and #line > 0 then
                    api.nvim_buf_set_extmark(bufnr, visual_ns_id, row, 0, {
                        end_col = #line,
                        hl_group = "Visual",
                        hl_mode = "combine",
                        priority = 101,
                    })
                end
            end
        end
    end
    M.refresh_syntax(bufnr)
end

function M.refresh_syntax(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    api.nvim_buf_clear_namespace(bufnr, syntax_ns_id, 0, -1)
    for _, source in ipairs(shown_source_rows(bufnr)) do
        local line = api.nvim_buf_get_lines(bufnr, source.row, source.row + 1, false)[1]
        if line and #line > 0 then
            local ft = vim.filetype.match { filename = source.meta.filename }
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
                                for capture_id, node in query:iter_captures(tree:root(), line, 0, -1) do
                                    local _, s_col, _, e_col = node:range()
                                    api.nvim_buf_set_extmark(bufnr, syntax_ns_id, source.row, s_col, {
                                        end_col = e_col,
                                        hl_group = "@" .. query.captures[capture_id] .. "." .. lang,
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

local function source_rows(bufnr)
    local rows = {}
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local meta = M.buffer_data[bufnr][extmark[1]]
        if meta then
            rows[meta.filename .. "\0" .. meta.lnum] = meta.buffer_row
            for _, entry in ipairs(meta.context or {}) do
                rows[meta.filename .. "\0" .. entry.lnum] = entry.buffer_row
            end
        end
    end
    return rows
end

---Return the displayed baseline (original_text) for a shown source row.
---When a source row is already shown (owned by another match or context
---entry), its baseline is whatever is currently recorded as original_text
---for that row. New context entries sharing that row must inherit the same
---baseline so apply_edits never flags a spurious edit from a stale disk
---read.
local function existing_baseline(bufnr, filename, lnum)
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local meta = M.buffer_data[bufnr][extmark[1]]
        if meta and meta.filename == filename then
            if meta.lnum == lnum then
                return meta.original_text
            end
            for _, entry in ipairs(meta.context or {}) do
                if entry.lnum == lnum then
                    return entry.original_text
                end
            end
        end
    end
    return nil
end

local function insert_source_row(bufnr, owner_meta, lnum, text)
    -- Dedup: if the candidate source lnum is already shown anywhere,
    -- reuse that row instead of inserting.
    local rows = source_rows(bufnr)
    local key = owner_meta.filename .. "\0" .. lnum
    if rows[key] ~= nil then
        return rows[key]
    end

    -- Determine the owning match's block: the contiguous region of rows
    -- belonging to this match (its anchor row ± its existing context
    -- rows). New upper context inserts just above the block's top; new
    -- lower context inserts just below the block's bottom.
    local block_top = owner_meta.buffer_row
    local block_bottom = owner_meta.buffer_row
    for _, entry in ipairs(owner_meta.context or {}) do
        block_top = math.min(block_top, entry.buffer_row)
        block_bottom = math.max(block_bottom, entry.buffer_row)
    end

    local insert_at
    if lnum < owner_meta.lnum then
        insert_at = block_top
    else
        insert_at = block_bottom + 1
    end

    api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false, { text })
    shift_rows(bufnr, insert_at, 1)
    return insert_at
end

---Physically reorder all shown source rows by (filename, lnum) so that
---same-file blocks are always contiguous in the buffer, regardless of
---the order in which matches were expanded.  Dedup still prevents
---duplicate source rows, but the physical buffer layout is rebuilt so
---that a match's context rows are always adjacent to its anchor.
local function reorder_buffer(bufnr)
    local source_rows = shown_source_rows(bufnr)

    -- Sort by (filename, lnum). Match anchors with the same
    -- (filename, lnum) are kept as distinct rows, ordered by their
    -- extmark id (a stable proxy for insertion order / column).
    table.sort(source_rows, function(a, b)
        if a.filename ~= b.filename then
            return a.filename < b.filename
        end
        if a.lnum ~= b.lnum then
            return a.lnum < b.lnum
        end
        -- Same filename:lnum — both could be match anchors. Order by
        -- match_id (extmark id) for a stable, deterministic sort.
        if a.kind == "match" and b.kind == "match" then
            return a.match_id < b.match_id
        end
        -- A match anchor sorts before a context row at the same
        -- filename:lnum (context rows are deduped away from match
        -- anchors anyway, so this is defensive).
        return a.kind == "match"
    end)

    -- Build new buffer lines: header + sorted source rows.
    local new_lines = vim.deepcopy(HEADER_TEXT)
    for _, source in ipairs(source_rows) do
        local text = api.nvim_buf_get_lines(bufnr, source.row, source.row + 1, false)[1]
        table.insert(new_lines, text)
    end

    M._programmatic[bufnr] = true
    api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)

    -- Build a lookup from (filename, lnum) to the list of row numbers
    -- in the new buffer. Match anchors at the same filename:lnum each
    -- get their own distinct row (in sorted order). Context rows dedup
    -- to one row per filename:lnum not occupied by a match anchor.
    local row_lookup = {}
    for i, source in ipairs(source_rows) do
        local key = source.filename .. "\0" .. source.lnum
        row_lookup[key] = row_lookup[key] or {}
        table.insert(row_lookup[key], HEADER_LINES + i - 1)
    end

    -- Update buffer_row for all matches. Each match anchor gets its
    -- own distinct row from the lookup (consumed in extmark-id order
    -- to match the sort order above).
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local id, meta = extmark[1], M.buffer_data[bufnr][extmark[1]]
        if meta then
            local key = meta.filename .. "\0" .. meta.lnum
            local slots = row_lookup[key]
            if slots and #slots > 0 then
                meta.buffer_row = slots[1]
                table.remove(slots, 1)
            end
        end
    end

    -- Update buffer_row for all context entries. Context rows dedup
    -- to the remaining slot for their filename:lnum (if any).
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local meta = M.buffer_data[bufnr][extmark[1]]
        if meta then
            for _, entry in ipairs(meta.context or {}) do
                local key = meta.filename .. "\0" .. entry.lnum
                local slots = row_lookup[key]
                if slots and #slots > 0 then
                    entry.buffer_row = slots[1]
                end
            end
        end
    end

    -- Reposition extmarks to their new rows.
    for id, meta in pairs(M.buffer_data[bufnr] or {}) do
        api.nvim_buf_set_extmark(bufnr, ns_id, meta.buffer_row, 0, { id = id })
    end
end

local function current_location(bufnr, row)
    row = row or (api.nvim_win_get_cursor(0)[1] - 1)
    return M.line_at_row(bufnr, row)
end

---Expand the owning match's window by three lines on each side.
---@param bufnr? integer
---@param row? integer zero-based buffer row; defaults to cursor
function M.expand_context(bufnr, row)
    bufnr = bufnr or api.nvim_get_current_buf()
    local location = current_location(bufnr, row)
    if not location then
        vim.notify("No grep result on this line", vim.log.levels.WARN)
        return false
    end

    local meta = location.meta
    if vim.fn.filereadable(meta.filename) ~= 1 then
        vim.notify("Cannot read file: " .. meta.filename, vim.log.levels.ERROR)
        return false
    end
    M._programmatic[bufnr] = true
    local file_lines = vim.fn.readfile(meta.filename)
    local target_up = math.min(meta.lnum - 1, meta.expand_up + EXPAND_STEP)
    local target_down = math.min(#file_lines - meta.lnum, meta.expand_down + EXPAND_STEP)
    local owned = {}
    for _, entry in ipairs(meta.context) do
        owned[entry.lnum] = true
    end
    meta.expand_up, meta.expand_down = target_up, target_down

    local wanted_up = {}
    for lnum = meta.lnum - target_up, meta.lnum - 1 do
        if not owned[lnum] then
            table.insert(wanted_up, lnum)
        end
    end
    local wanted_down = {}
    for lnum = meta.lnum + 1, meta.lnum + target_down do
        if not owned[lnum] then
            table.insert(wanted_down, lnum)
        end
    end

    -- Process upper context in descending order (closest to match first)
    -- so each insert goes just above the growing block top, preserving
    -- ascending source order in the buffer.
    table.sort(wanted_up, function(a, b)
        return a > b
    end)
    -- Process lower context in ascending order (closest to match first)
    -- so each insert goes just below the growing block bottom.
    table.sort(wanted_down)

    local function process_lnum(lnum)
        local key = meta.filename .. "\0" .. lnum
        local buffer_row = source_rows(bufnr)[key]
        if not buffer_row then
            buffer_row = insert_source_row(bufnr, meta, lnum, file_lines[lnum])
        end
        -- When the source row is already shown (shared with another
        -- expanded match), inherit the existing displayed baseline
        -- instead of reading from disk. This prevents stale-overlap
        -- apply bugs where a newer context entry flags a spurious edit
        -- because its original_text came from a changed-on-disk file.
        local baseline = existing_baseline(bufnr, meta.filename, lnum)
        table.insert(meta.context, {
            lnum = lnum,
            original_text = baseline or file_lines[lnum],
            buffer_row = buffer_row,
        })
        owned[lnum] = true
    end

    for _, lnum in ipairs(wanted_up) do
        process_lnum(lnum)
    end
    for _, lnum in ipairs(wanted_down) do
        process_lnum(lnum)
    end

    table.sort(meta.context, function(a, b)
        return a.lnum < b.lnum
    end)
    -- Reorder the entire buffer so all shown source rows are sorted by
    -- (filename, lnum).  This ensures same-file blocks are contiguous,
    -- even when matches from different files were expanded in an order
    -- that would otherwise interleave a foreign file's rows between a
    -- match and its reused (deduped) context rows.
    reorder_buffer(bufnr)
    refresh_views(bufnr)
    return true
end

---Collapse all context owned by the match under the supplied row/cursor.
function M.collapse_context(bufnr, row)
    bufnr = bufnr or api.nvim_get_current_buf()
    local location = current_location(bufnr, row)
    if not location then
        vim.notify("No grep result on this line", vim.log.levels.WARN)
        return false
    end

    local meta = location.meta
    M._programmatic[bufnr] = true
    local owned_rows = {}
    for _, entry in ipairs(meta.context) do
        owned_rows[context_row(bufnr, entry)] = true
    end
    meta.context = {}
    meta.expand_up = 0
    meta.expand_down = 0

    local covered_rows = {}
    for _, other_meta in pairs(M.buffer_data[bufnr] or {}) do
        covered_rows[other_meta.buffer_row] = true
        for _, entry in ipairs(other_meta.context or {}) do
            covered_rows[context_row(bufnr, entry)] = true
        end
    end
    local rows = {}
    for row in pairs(owned_rows) do
        if not covered_rows[row] then
            table.insert(rows, row)
        end
    end
    table.sort(rows, function(a, b)
        return a > b
    end)
    for _, entry_row in ipairs(rows) do
        api.nvim_buf_set_lines(bufnr, entry_row, entry_row + 1, false, {})
        shift_rows(bufnr, entry_row + 1, -1)
    end
    refresh_views(bufnr)

    local anchor_row = match_row(bufnr, location.match_id)
    if anchor_row and api.nvim_get_current_buf() == bufnr then
        pcall(api.nvim_win_set_cursor, 0, { anchor_row + 1, 0 })
    end
    return true
end

---Navigate from a match or context row to its source line.
function M.nav_to_match()
    local bufnr = api.nvim_get_current_buf()
    local location = current_location(bufnr)
    if not location then
        vim.notify("No grep result on this line", vim.log.levels.WARN)
        return
    end

    local lnum = location.entry and location.entry.lnum or location.meta.lnum
    local col = location.entry and 1 or location.meta.col
    if vim.fn.filereadable(location.meta.filename) == 0 then
        vim.notify("File not found: " .. location.meta.filename, vim.log.levels.ERROR)
        return
    end
    vim.cmd.edit(location.meta.filename)
    pcall(api.nvim_win_set_cursor, 0, { lnum, col - 1 })
    vim.cmd "normal! zz"
end

function M.create_buffer(lines)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "grep"
    vim.cmd.buffer(buf)
end

local function collect_edits(bufnr)
    local edits = {}
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local id, row = extmark[1], extmark[2]
        local meta = M.buffer_data[bufnr][id]
        if meta then
            local current = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
            if current and current ~= meta.original_text then
                table.insert(edits, {
                    filename = meta.filename,
                    lnum = meta.lnum,
                    original = meta.original_text,
                    new = current,
                    row = row,
                })
            end
            for _, entry in ipairs(meta.context) do
                local entry_row = context_row(bufnr, entry)
                current = api.nvim_buf_get_lines(bufnr, entry_row, entry_row + 1, false)[1]
                if current and current ~= entry.original_text then
                    table.insert(edits, {
                        filename = meta.filename,
                        lnum = entry.lnum,
                        original = entry.original_text,
                        new = current,
                        row = entry_row,
                    })
                end
            end
        end
    end
    return edits
end

---Apply shown match and context edits to their source files.
function M.apply_edits(mode)
    local bufnr = api.nvim_get_current_buf()
    if not M.buffer_data[bufnr] then
        return
    end

    local file_edits, seen = {}, {}
    local edits = collect_edits(bufnr)
    table.sort(edits, function(a, b)
        return a.row < b.row
    end)
    for _, edit in ipairs(edits) do
        local key = edit.filename .. "\0" .. edit.lnum
        if seen[key] then
            if seen[key].new ~= edit.new then
                vim.notify(
                    string.format("Divergent duplicate skipped: %s:%d", edit.filename, edit.lnum),
                    vim.log.levels.WARN
                )
            end
        else
            seen[key] = edit
            file_edits[edit.filename] = file_edits[edit.filename] or {}
            table.insert(file_edits[edit.filename], edit)
        end
    end

    for filename, edits in pairs(file_edits) do
        table.sort(edits, function(a, b)
            return a.lnum > b.lnum
        end)
        if vim.fn.filereadable(filename) ~= 1 then
            vim.notify("File missing: " .. filename, vim.log.levels.ERROR)
        else
            local file_lines = vim.fn.readfile(filename)
            local modified_count = 0
            for _, edit in ipairs(edits) do
                local file_content = file_lines[edit.lnum]
                if not file_content or file_content ~= edit.original then
                    vim.notify(string.format("Conflict in %s:%d. Skipping.", filename, edit.lnum), vim.log.levels.WARN)
                elseif mode == "direct" then
                    file_lines[edit.lnum] = edit.new
                    modified_count = modified_count + 1
                elseif mode == "conflict" then
                    local conflict = { "<<<<<<< LOCAL", file_content, "=======", edit.new, ">>>>>>> REMOTE" }
                    table.remove(file_lines, edit.lnum)
                    for index = #conflict, 1, -1 do
                        table.insert(file_lines, edit.lnum, conflict[index])
                    end
                    modified_count = modified_count + 1
                end
            end
            if modified_count > 0 then
                vim.fn.writefile(file_lines, filename)
                vim.notify(string.format("Applied %d changes to %s", modified_count, filename))
            end
        end
    end
end

---Refresh all shown match and context rows from disk without changing expansion.
function M.refresh_content()
    local bufnr = api.nvim_get_current_buf()
    if not M.buffer_data[bufnr] then
        return
    end

    M._programmatic[bufnr] = true

    local file_cache = {}
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local meta = M.buffer_data[bufnr][extmark[1]]
        if meta and not file_cache[meta.filename] and vim.fn.filereadable(meta.filename) == 1 then
            file_cache[meta.filename] = vim.fn.readfile(meta.filename)
        end
    end

    local updates_made = false
    for _, extmark in ipairs(match_extmarks(bufnr)) do
        local id, row = extmark[1], extmark[2]
        local meta = M.buffer_data[bufnr][id]
        local file_lines = meta and file_cache[meta.filename]
        if file_lines then
            local text = file_lines[meta.lnum]
            if text then
                if api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] ~= text then
                    api.nvim_buf_set_lines(bufnr, row, row + 1, false, { text })
                    updates_made = true
                end
                meta.original_text = text
            end
            for _, entry in ipairs(meta.context) do
                text = file_lines[entry.lnum]
                if text then
                    local entry_row = context_row(bufnr, entry)
                    if api.nvim_buf_get_lines(bufnr, entry_row, entry_row + 1, false)[1] ~= text then
                        api.nvim_buf_set_lines(bufnr, entry_row, entry_row + 1, false, { text })
                        updates_made = true
                    end
                    entry.original_text = text
                end
            end
        end
    end
    refresh_views(bufnr)
    vim.notify(updates_made and "Buffer content refreshed from disk" or "No changes found on disk", vim.log.levels.INFO)
end

function M.kill_buffer()
    api.nvim_buf_delete(api.nvim_get_current_buf(), { force = true })
end

---Guard callback: reject user-driven structural line edits (insert/delete
---of whole lines) by collapsing ALL expanded context in the buffer.
---This returns the buffer to bare match lines — a known-consistent
---state — so metadata can never desync. In-place text edits are
---unaffected because the line count does not change.
function M._guard_callback(bufnr)
    if M._programmatic[bufnr] then
        return
    end
    local expected = M.expected_line_count[bufnr]
    if expected == nil then
        return
    end
    local actual = api.nvim_buf_line_count(bufnr)
    if actual == expected then
        return
    end

    -- Rebuild the buffer to bare match lines: header + one line per
    -- match (using original_text for a known-consistent state).
    M._programmatic[bufnr] = true

    local extmarks = match_extmarks(bufnr)
    local match_metas = {}
    for _, extmark in ipairs(extmarks) do
        local id = extmark[1]
        local meta = M.buffer_data[bufnr][id]
        if meta then
            table.insert(match_metas, { id = id, meta = meta })
        end
    end

    -- Clear all context metadata.
    for _, mm in ipairs(match_metas) do
        mm.meta.context = {}
        mm.meta.expand_up = 0
        mm.meta.expand_down = 0
    end

    -- Rebuild buffer lines: header + bare match lines.
    local new_lines = vim.deepcopy(HEADER_TEXT)
    for _, mm in ipairs(match_metas) do
        table.insert(new_lines, mm.meta.original_text)
    end
    api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)

    -- Reposition extmarks and update buffer_row.
    api.nvim_buf_clear_namespace(bufnr, frame_ns_id, 0, -1)
    api.nvim_buf_clear_namespace(bufnr, visual_ns_id, 0, -1)
    for i, mm in ipairs(match_metas) do
        local row = HEADER_LINES + i - 1
        api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, { id = mm.id })
        mm.meta.buffer_row = row
    end

    refresh_views(bufnr)

    vim.notify(
        "Structural line edits (insert/delete) are not supported in the grep buffer. Only in-place edits are allowed.",
        vim.log.levels.WARN
    )

    -- Return the user to Normal mode if the structural edit happened in
    -- Insert mode (e.g. TextChangedI).
    pcall(vim.cmd, "stopinsert")
end

---Register the structural-edit guard autocmd for a processed buffer.
---Called once per buffer from highlight_buffer. Not in ftplugin.
function M._setup_guard(bufnr)
    if vim.b[bufnr].grep_guard_setup then
        return
    end
    vim.b[bufnr].grep_guard_setup = true
    api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
        buffer = bufnr,
        callback = function()
            M._guard_callback(bufnr)
        end,
    })
end

return M
