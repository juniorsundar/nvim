local grep = require "buffers.grep"

local api = vim.api

local function write_fixture(lines)
    local path = vim.fn.tempname() .. ".lua"
    vim.fn.writefile(lines, path)
    return path
end

local function make_grep_buffer(path, matches)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, matches)
    api.nvim_set_current_buf(buf)
    grep.highlight_buffer(buf)
    return buf
end

local function row_for(buf, predicate)
    for row, location in pairs(grep.row_index[buf]) do
        if predicate(location) then
            return row
        end
    end
end

local function namespace(name)
    return api.nvim_create_namespace(name)
end

local function extmarks_with_virt_lines(buf, ns)
    return vim.tbl_filter(function(mark)
        return mark[4].virt_lines ~= nil
    end, api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true }))
end

local function row_for_source(buf, lnum)
    for row in pairs(grep.row_index[buf]) do
        local location = grep.line_at_row(buf, row)
        local source_lnum = location.entry and location.entry.lnum or location.meta.lnum
        if source_lnum == lnum then
            return row
        end
    end
end

describe("buffers.grep context", function()
    local buffers = {}
    local files = {}

    after_each(function()
        local replacement = api.nvim_create_buf(false, true)
        api.nvim_set_current_buf(replacement)
        for _, buf in ipairs(buffers) do
            if api.nvim_buf_is_valid(buf) then
                api.nvim_buf_delete(buf, { force = true })
            end
        end
        buffers = {}
        for _, path in ipairs(files) do
            vim.fn.delete(path)
        end
        files = {}
    end)

    it("expands, grows, clamps, and collapses a match window", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":2:1:two" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        assert.is_true(grep.expand_context(buf, match_row))
        local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
        assert.are.same({ "one", "two", "three", "four", "five" }, { lines[1], lines[2], lines[3], lines[4], lines[5] })
        local _, meta = next(grep.buffer_data[buf])
        assert.are.equal(1, meta.expand_up)
        assert.are.equal(3, meta.expand_down)
        assert.are.equal(4, #meta.context)

        assert.is_true(grep.expand_context(buf, match_row))
        _, meta = next(grep.buffer_data[buf])
        assert.are.equal(1, meta.expand_up)
        assert.are.equal(6, meta.expand_down)
        assert.are.equal(7, #meta.context)

        assert.is_true(grep.collapse_context(buf, match_row))
        _, meta = next(grep.buffer_data[buf])
        assert.are.same({}, meta.context)
        assert.are.equal(0, meta.expand_up)
        assert.are.equal(0, meta.expand_down)
        assert.are.same({ "two" }, api.nvim_buf_get_lines(buf, 0, -1, false))
    end)

    it("retains shared rows when collapsing an overlapping context block", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:1:four", path .. ":6:1:six" })
        table.insert(buffers, buf)
        local first_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 4
        end)
        assert.is_true(grep.expand_context(buf, first_match_row))
        local second_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 6
        end)
        assert.is_true(grep.expand_context(buf, second_match_row))

        assert.is_true(grep.collapse_context(buf, first_match_row))
        local remaining_lnums = {}
        for row, location in pairs(grep.row_index[buf]) do
            local meta = grep.buffer_data[buf][location.match_id]
            local lnum = location.kind == "match" and meta.lnum or meta.context[location.context_index].lnum
            remaining_lnums[lnum] = api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
        end
        assert.is_nil(remaining_lnums[1])
        assert.is_nil(remaining_lnums[2])
        assert.are.same(
            { [3] = "three", [4] = "four", [5] = "five", [6] = "six", [7] = "seven", [8] = "eight", [9] = "nine" },
            remaining_lnums
        )
    end)

    it("renders headers for an expanded block whose context is fully deduped", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":3:1:three", path .. ":4:1:four" })
        table.insert(buffers, buf)
        local first_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 3
        end)
        assert.is_true(grep.expand_context(buf, first_match_row))
        local second_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 4
        end)
        assert.is_true(grep.expand_context(buf, second_match_row))

        local frame_ns = namespace "buffers_grep_context_headers"
        local frames = extmarks_with_virt_lines(buf, frame_ns)
        assert.are.equal(2, #frames)
        local top_row = row_for_source(buf, 1)
        local bottom_row = row_for_source(buf, 6)
        assert.are.same(
            { top_row, bottom_row },
            vim.tbl_map(function(frame)
                return frame[2]
            end, frames)
        )
    end)

    it("selects the topmost closest anchor for a shared context row", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:1:four", path .. ":6:1:six" })
        table.insert(buffers, buf)
        local first_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 4
        end)
        assert.is_true(grep.expand_context(buf, first_match_row))
        local second_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 6
        end)
        assert.is_true(grep.expand_context(buf, second_match_row))

        local shared_row = row_for(buf, function(location)
            local meta = grep.buffer_data[buf][location.match_id]
            return location.kind == "context" and meta.context[location.context_index].lnum == 5
        end)
        assert.are.equal(2, #grep.row_index[buf][shared_row].members)
        local location = grep.line_at_row(buf, shared_row)
        assert.are.equal(4, location.meta.lnum)
        assert.is_true(grep.collapse_context(buf, shared_row))
        local metas = vim.tbl_values(grep.buffer_data[buf])
        table.sort(metas, function(a, b)
            return a.lnum < b.lnum
        end)
        assert.are.same({}, metas[1].context)
        assert.is_true(#metas[2].context > 0)
    end)

    it("preserves bare-match apply and refresh behavior", function()
        local path = write_fixture { "one", "two", "three" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":2:1:two" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        api.nvim_buf_set_lines(buf, match_row, match_row + 1, false, { "TWO" })
        grep.apply_edits "direct"
        assert.are.equal("TWO", vim.fn.readfile(path)[2])

        vim.fn.writefile({ "one", "disk-two", "three" }, path)
        grep.refresh_content()
        assert.are.equal("disk-two", api.nvim_buf_get_lines(buf, match_row, match_row + 1, false)[1])
        local _, meta = next(grep.buffer_data[buf])
        assert.are.same({}, meta.context)
    end)

    it("renders one virtual filename header for an expanded block", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:1:four" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        grep.expand_context(buf, match_row)

        local frame_ns = namespace "buffers_grep_context_headers"
        local frames = extmarks_with_virt_lines(buf, frame_ns)
        assert.are.equal(2, #frames)
        local header = frames[1][4].virt_lines[1]
        assert.are.equal("┌─ ", header[1][1])
        assert.are.equal(
            path,
            table.concat(vim.tbl_map(function(chunk)
                return chunk[1]
            end, vim.list_slice(header, 2, #header - 1)))
        )
        assert.is_true(header[#header][1]:match "^ " .. string.rep("─", 80) ~= nil)
        assert.are.equal("└" .. string.rep("─", 82), frames[2][4].virt_lines[1][1][1])

        grep.collapse_context(buf, match_row)
        assert.are.equal(0, #api.nvim_buf_get_extmarks(buf, frame_ns, 0, -1, {}))
    end)

    it("renders merged region frames and signs once per shown source line", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":3:1:three", path .. ":4:1:four" })
        table.insert(buffers, buf)
        local first_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 3
        end)
        assert.is_true(grep.expand_context(buf, first_match_row))
        local second_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 4
        end)
        assert.is_true(grep.expand_context(buf, second_match_row))

        local frame_ns = namespace "buffers_grep_context_headers"
        local marks = api.nvim_buf_get_extmarks(buf, frame_ns, 0, -1, { details = true })
        local frames = extmarks_with_virt_lines(buf, frame_ns)
        local signs = vim.tbl_filter(function(mark)
            return mark[4].sign_text and mark[4].sign_text:match "^%s+$"
        end, marks)
        assert.are.equal(2, #frames)
        assert.are.equal(6, #signs)
        assert.are.same(
            {
                "GrepContextSign",
                "GrepContextSign",
                "GrepContextSign",
                "GrepContextSign",
                "GrepContextSign",
                "GrepContextSign",
            },
            vim.tbl_map(function(sign)
                return sign[4].sign_hl_group
            end, signs)
        )
        assert.are.same(
            { "GrepContextBorder", "GrepContextBorder" },
            vim.tbl_map(function(frame)
                return frame[4].virt_lines[1][1][2]
            end, frames)
        )
    end)

    it("prefixes collapsed matches, emphasizes expanded anchors, and clears stale decorations", function()
        local path =
            write_fixture { "local one = 1", "local two = 2", "local three = 3", "local four = 4", "local five = 5" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":3:1:local three = 3" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        local prefix_ns = namespace "buffers_grep_syntax"
        local visual_ns = namespace "buffers_grep_context_visual"
        local function marks_at(ns, row)
            return api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, -1 }, { details = true })
        end

        local prefix = marks_at(prefix_ns, match_row)[1]
        assert.are.equal(
            path .. ":3:1:",
            table.concat(vim.tbl_map(function(chunk)
                return chunk[1]
            end, prefix[4].virt_text))
        )
        assert.are.equal(0, #marks_at(visual_ns, match_row))

        assert.is_true(grep.expand_context(buf, match_row))
        match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        prefix = marks_at(prefix_ns, match_row)[1]
        assert.is_nil(prefix[4].virt_text)
        local visual = marks_at(visual_ns, match_row)[1]
        assert.are.same("Visual", visual[4].hl_group)
        assert.are.equal(#"local three = 3", visual[4].end_col)

        assert.is_true(grep.collapse_context(buf, match_row))
        match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        prefix = marks_at(prefix_ns, match_row)[1]
        assert.are.equal(
            path .. ":3:1:",
            table.concat(vim.tbl_map(function(chunk)
                return chunk[1]
            end, prefix[4].virt_text))
        )
        assert.are.equal(0, #marks_at(visual_ns, match_row))
    end)

    it("highlights source syntax for match and context rows when the Lua parser is available", function()
        local path =
            write_fixture { "local one = 1", "local two = 2", "local three = 3", "local four = 4", "local five = 5" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":3:1:local three = 3" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.is_true(grep.expand_context(buf, match_row))
        local context_row = row_for(buf, function(location)
            local meta = grep.buffer_data[buf][location.match_id]
            return location.kind == "context" and meta.context[location.context_index].lnum == 2
        end)
        local syntax_ns = namespace "buffers_grep_syntax_highlight"
        assert.is_true(#api.nvim_buf_get_extmarks(buf, syntax_ns, { match_row, 0 }, { match_row, -1 }, {}) > 0)
        assert.is_true(#api.nvim_buf_get_extmarks(buf, syntax_ns, { context_row, 0 }, { context_row, -1 }, {}) > 0)
    end)

    it("applies, refreshes, and navigates context rows", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:2:four" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.is_true(grep.expand_context(buf, match_row))

        local context_row = row_for(buf, function(location)
            local meta = grep.buffer_data[buf][location.match_id]
            return location.kind == "context" and meta.context[location.context_index].lnum == 2
        end)
        api.nvim_buf_set_lines(buf, context_row, context_row + 1, false, { "TWO" })
        grep.apply_edits "direct"
        assert.are.equal("TWO", vim.fn.readfile(path)[2])

        vim.fn.writefile({ "one", "disk-two", "three", "four", "five", "six", "seven" }, path)
        grep.refresh_content()
        assert.are.equal("disk-two", api.nvim_buf_get_lines(buf, context_row, context_row + 1, false)[1])

        api.nvim_win_set_cursor(0, { context_row + 1, 0 })
        grep.nav_to_match()
        assert.are.equal(vim.fn.fnamemodify(path, ":p"), vim.fn.expand "%:p")
        assert.are.equal(2, api.nvim_win_get_cursor(0)[1])
    end)

    it("applies context edits as conflict markers", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:1:four" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        grep.expand_context(buf, match_row)
        local context_row = row_for(buf, function(location)
            local meta = grep.buffer_data[buf][location.match_id]
            return location.kind == "context" and meta.context[location.context_index].lnum == 3
        end)
        api.nvim_buf_set_lines(buf, context_row, context_row + 1, false, { "THREE" })
        grep.apply_edits "conflict"
        assert.are.same({
            "one",
            "two",
            "<<<<<<< LOCAL",
            "three",
            "=======",
            "THREE",
            ">>>>>>> REMOTE",
            "four",
            "five",
            "six",
            "seven",
        }, vim.fn.readfile(path))
    end)

    it("reports a conflict and skips when the on-disk line no longer matches exactly", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:1:four" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        -- Edit the match line in the buffer.
        api.nvim_buf_set_lines(buf, match_row, match_row + 1, false, { "FOUR" })
        -- Change the same line on disk so the original_text no longer matches exactly.
        vim.fn.writefile({ "one", "two", "three", "prefix-four", "five", "six", "seven" }, path)

        grep.apply_edits "direct"
        -- The on-disk line must NOT be overwritten; it stays as the external change.
        assert.are.equal("prefix-four", vim.fn.readfile(path)[4])
    end)

    it("does not revert disk changes when an overlapping expansion shares a stale source row", function()
        local path = write_fixture { "L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:1:L4", path .. ":6:1:L6" })
        table.insert(buffers, buf)

        local first_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 4
        end)
        assert.is_true(grep.expand_context(buf, first_match_row))
        -- L5 is now shown as context for match 4.  Modify L5 on disk.
        local disk_lines = vim.fn.readfile(path)
        disk_lines[5] = "L5-CHANGED"
        vim.fn.writefile(disk_lines, path)

        -- Expand match 6.  L5 is already shown (shared with match 4's
        -- context), so the new context entry must inherit the displayed
        -- baseline instead of reading the changed-on-disk content.
        local second_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 6
        end)
        assert.is_true(grep.expand_context(buf, second_match_row))

        -- apply_edits direct must NOT revert the disk change on L5.
        grep.apply_edits "direct"
        assert.are.equal("L5-CHANGED", vim.fn.readfile(path)[5])
    end)

    it("rejects user-driven structural line inserts and collapses all context", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":2:1:two" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        -- Expand context so there is context to collapse.
        assert.is_true(grep.expand_context(buf, match_row))
        local match_count = 1
        local expected_after_collapse = match_count

        -- Simulate a user inserting a whole line, then fire TextChanged
        -- as Neovim would for a user-initiated change.
        api.nvim_buf_set_lines(buf, match_row, match_row, false, { "INSERTED" })
        api.nvim_exec_autocmds("TextChanged", { buffer = buf })

        -- After the rejected edit, all context is collapsed.
        assert.are.equal(expected_after_collapse, api.nvim_buf_line_count(buf))
        for _, meta in pairs(grep.buffer_data[buf]) do
            assert.are.same({}, meta.context)
        end
    end)

    it("rejects user-driven structural line deletes and collapses all context", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":2:1:two" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        -- Expand context so there is context to collapse.
        assert.is_true(grep.expand_context(buf, match_row))
        local match_count = 1
        local expected_after_collapse = match_count

        local lines_before = api.nvim_buf_get_lines(buf, 0, -1, false)
        api.nvim_buf_set_lines(buf, match_row, match_row + 1, false, {})
        api.nvim_exec_autocmds("TextChanged", { buffer = buf })

        -- After the rejected edit, all context is collapsed.
        assert.are.equal(expected_after_collapse, api.nvim_buf_line_count(buf))
        for _, meta in pairs(grep.buffer_data[buf]) do
            assert.are.same({}, meta.context)
        end
    end)

    it("allows in-place text edits and applies them to disk", function()
        local path = write_fixture { "one", "two", "three" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":2:1:two" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        local expected = grep.expected_line_count[buf]

        -- Simulate a user in-place edit, then fire TextChanged.
        api.nvim_buf_set_lines(buf, match_row, match_row + 1, false, { "TWO" })
        api.nvim_exec_autocmds("TextChanged", { buffer = buf })

        -- The edit is preserved (line count unchanged).
        assert.are.equal(expected, api.nvim_buf_line_count(buf))
        assert.are.equal("TWO", api.nvim_buf_get_lines(buf, match_row, match_row + 1, false)[1])

        grep.apply_edits "direct"
        assert.are.equal("TWO", vim.fn.readfile(path)[2])
    end)

    it("keeps cross-file context contiguous with the owning match block", function()
        -- Matches ordered [fileA:2, fileB:1, fileA:6] so fileB:1 sits
        -- between the two fileA matches. Expanding fileA:2 must keep
        -- its lower context contiguous with fileA:2 and not interleave
        -- fileB:1.
        local pathA = write_fixture { "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8" }
        local pathB = write_fixture { "B1", "B2", "B3" }
        table.insert(files, pathA)
        table.insert(files, pathB)
        local buf = make_grep_buffer(pathA, { pathA .. ":2:1:A2", pathB .. ":1:1:B1", pathA .. ":6:1:A6" })
        table.insert(buffers, buf)

        local row_a2 = row_for(buf, function(location)
            return location.kind == "match"
                and grep.buffer_data[buf][location.match_id].lnum == 2
                and grep.buffer_data[buf][location.match_id].filename == pathA
        end)
        local row_b1 = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].filename == pathB
        end)
        local row_a6 = row_for(buf, function(location)
            return location.kind == "match"
                and grep.buffer_data[buf][location.match_id].lnum == 6
                and grep.buffer_data[buf][location.match_id].filename == pathA
        end)

        -- Initial order: A2, B1, A6 (rows ascending).
        assert.is_true(row_a2 < row_b1)
        assert.is_true(row_b1 < row_a6)

        -- Expand fileA:2. Its lower context (A3, A4, A5) must be
        -- contiguous with A2, not interleaved with B1.
        assert.is_true(grep.expand_context(buf, row_a2))

        -- Re-fetch rows after expansion.
        row_a2 = row_for(buf, function(location)
            return location.kind == "match"
                and grep.buffer_data[buf][location.match_id].lnum == 2
                and grep.buffer_data[buf][location.match_id].filename == pathA
        end)
        row_b1 = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].filename == pathB
        end)
        row_a6 = row_for(buf, function(location)
            return location.kind == "match"
                and grep.buffer_data[buf][location.match_id].lnum == 6
                and grep.buffer_data[buf][location.match_id].filename == pathA
        end)

        -- Collect all source lnums for fileA:2's context block.
        local a2_meta = grep.buffer_data[buf][grep.row_index[buf][row_a2].match_id]
        local block_lnums = {}
        for _, entry in ipairs(a2_meta.context) do
            table.insert(block_lnums, entry.lnum)
        end
        table.sort(block_lnums)

        -- The context for A2 should include A1 (upper) and A3, A4, A5 (lower).
        assert.are.same({ 1, 3, 4, 5 }, block_lnums)

        -- All context rows for A2 must be contiguous with A2's match row,
        -- meaning B1 must NOT appear between A2 and its context.
        -- A2's block spans from the lowest context row to the highest.
        local block_rows = { row_a2 }
        for _, entry in ipairs(a2_meta.context) do
            table.insert(block_rows, entry.buffer_row)
        end
        table.sort(block_rows)
        local block_top, block_bottom = block_rows[1], block_rows[#block_rows]

        -- B1 must be outside the A2 block.
        assert.is_true(
            row_b1 < block_top or row_b1 > block_bottom,
            "fileB:1 must not be inside fileA:2's context block"
        )

        -- Specifically, B1 should be below the A2 block (since B1 was
        -- originally between A2 and A6, and A2's context grows downward
        -- adjacent to A2, pushing B1 down).
        assert.is_true(block_bottom < row_b1, "fileA:2's context must be contiguous and above fileB:1")
    end)

    it("keeps cross-file context contiguous when expanding in reverse order", function()
        -- Matches ordered [fileA:2, fileB:1, fileA:6]. Expand fileA:6
        -- FIRST, then fileA:2. fileA:2's lower context (A3, A4, A5) may
        -- be reused via dedup if already shown, but the buffer must be
        -- reordered so fileA rows are contiguous — no fileB row between
        -- fileA:2's context and fileA:6's block.
        local pathA = write_fixture { "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8" }
        local pathB = write_fixture { "B1", "B2", "B3" }
        table.insert(files, pathA)
        table.insert(files, pathB)
        local buf = make_grep_buffer(pathA, { pathA .. ":2:1:A2", pathB .. ":1:1:B1", pathA .. ":6:1:A6" })
        table.insert(buffers, buf)

        local function find_row(filename, lnum)
            return row_for(buf, function(location)
                return location.kind == "match"
                    and grep.buffer_data[buf][location.match_id].lnum == lnum
                    and grep.buffer_data[buf][location.match_id].filename == filename
            end)
        end

        local row_a6 = find_row(pathA, 6)
        local row_b1 = find_row(pathB, 1)

        -- Expand fileA:6 first.
        assert.is_true(grep.expand_context(buf, row_a6))

        -- Then expand fileA:2.
        local row_a2 = find_row(pathA, 2)
        assert.is_true(grep.expand_context(buf, row_a2))

        -- Re-fetch all rows after both expansions.
        row_a2 = find_row(pathA, 2)
        row_b1 = find_row(pathB, 1)
        row_a6 = find_row(pathA, 6)

        -- Gather all fileA source rows (match + context) and verify
        -- they form a contiguous block with no fileB row in between.
        local fileA_rows = {}
        for row, location in pairs(grep.row_index[buf]) do
            local meta = grep.buffer_data[buf][location.match_id]
            if meta.filename == pathA then
                fileA_rows[row] = true
            end
        end
        local sorted_a_rows = vim.tbl_keys(fileA_rows)
        table.sort(sorted_a_rows)

        -- All rows between the first and last fileA row must be fileA
        -- rows (no fileB interleave).
        for r = sorted_a_rows[1], sorted_a_rows[#sorted_a_rows] do
            assert.is_true(
                fileA_rows[r],
                string.format("row %d is between fileA rows but is not fileA (fileB interleaved)", r)
            )
        end

        -- fileB:1 must be outside the fileA block.
        assert.is_true(
            row_b1 < sorted_a_rows[1] or row_b1 > sorted_a_rows[#sorted_a_rows],
            "fileB:1 must not be between fileA rows"
        )
    end)

    it("guard collapses context and returns to Normal mode on structural insert edit", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":2:1:two" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        -- Expand context so there is context to collapse.
        assert.is_true(grep.expand_context(buf, match_row))

        -- Enter insert mode to simulate a user structural edit in insert mode.
        -- In headless mode, startinsert may not fully transition mode, so
        -- use feedkeys to ensure the mode transition takes effect.
        api.nvim_feedkeys(api.nvim_replace_termcodes("i", true, true, true), "nt", false)

        -- Simulate a user inserting a whole line, then fire TextChangedI
        -- as Neovim would for a user-initiated change in insert mode.
        api.nvim_buf_set_lines(buf, match_row, match_row, false, { "INSERTED" })
        api.nvim_exec_autocmds("TextChangedI", { buffer = buf })

        -- After the rejected edit, all context is collapsed.
        local expected_after_collapse = 1
        assert.are.equal(expected_after_collapse, api.nvim_buf_line_count(buf))
        for _, meta in pairs(grep.buffer_data[buf]) do
            assert.are.same({}, meta.context)
        end

        -- The guard must have returned to Normal mode.
        assert.are.not_equal("i", vim.fn.mode())
        assert.are.not_equal("R", vim.fn.mode())
    end)

    it("toggle_context expands a collapsed match and collapses an expanded match", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:1:four" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        -- Match starts collapsed: toggle expands it.
        assert.is_true(grep.toggle_context(buf, match_row))
        local _, meta = next(grep.buffer_data[buf])
        assert.is_true(#meta.context > 0)
        assert.are.equal(3, meta.expand_up)
        assert.are.equal(3, meta.expand_down)

        -- Match now has context: toggle collapses it.
        match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.is_true(grep.toggle_context(buf, match_row))
        _, meta = next(grep.buffer_data[buf])
        assert.are.same({}, meta.context)
        assert.are.equal(0, meta.expand_up)
        assert.are.equal(0, meta.expand_down)
    end)

    it("toggle_context collapses a match expanded beyond ±3", function()
        local path =
            write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":6:1:six" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        -- Grow twice to reach ±6.
        assert.is_true(grep.grow_context(buf, match_row))
        assert.is_true(grep.grow_context(buf, match_row))
        local _, meta = next(grep.buffer_data[buf])
        assert.are.equal(5, meta.expand_up)
        assert.are.equal(5, meta.expand_down)
        assert.is_true(#meta.context > 0)

        -- Toggle collapses fully to 0 even though it was expanded beyond ±3.
        match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.is_true(grep.toggle_context(buf, match_row))
        _, meta = next(grep.buffer_data[buf])
        assert.are.same({}, meta.context)
        assert.are.equal(0, meta.expand_up)
        assert.are.equal(0, meta.expand_down)
    end)

    it("grow_context expands a collapsed match and grows an expanded match", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":5:1:five" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        -- Collapsed: grow expands to ±3.
        assert.is_true(grep.grow_context(buf, match_row))
        local _, meta = next(grep.buffer_data[buf])
        assert.are.equal(3, meta.expand_up)
        assert.are.equal(3, meta.expand_down)
        assert.are.equal(6, #meta.context)

        -- Already expanded: grow grows to ±6.
        match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.is_true(grep.grow_context(buf, match_row))
        _, meta = next(grep.buffer_data[buf])
        assert.are.equal(4, meta.expand_up)
        assert.are.equal(5, meta.expand_down)
        assert.are.equal(9, #meta.context)
    end)

    it("shrink_context shrinks an expanded window and collapses to 0", function()
        local path =
            write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":6:1:six" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        -- Grow twice to ±6 (clamped by file edges to ±5).
        assert.is_true(grep.grow_context(buf, match_row))
        assert.is_true(grep.grow_context(buf, match_row))
        local _, meta = next(grep.buffer_data[buf])
        assert.are.equal(5, meta.expand_up)
        assert.are.equal(5, meta.expand_down)

        -- Shrink by ±3: should go to ±2 (clamped).
        match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.is_true(grep.shrink_context(buf, match_row))
        _, meta = next(grep.buffer_data[buf])
        assert.are.equal(2, meta.expand_up)
        assert.are.equal(2, meta.expand_down)

        -- The outermost rows (lnum 1 and lnum 11) should no longer be shown.
        local shown_lnums = {}
        for row, location in pairs(grep.row_index[buf]) do
            local m = grep.buffer_data[buf][location.match_id]
            local lnum = location.kind == "match" and m.lnum or m.context[location.context_index].lnum
            shown_lnums[lnum] = true
        end
        assert.is_nil(shown_lnums[1])
        assert.is_nil(shown_lnums[11])
        assert.is.truthy(shown_lnums[4])
        assert.is.truthy(shown_lnums[8])

        -- Shrink again: ±2 - 3 = 0, fully collapsed.
        match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.is_true(grep.shrink_context(buf, match_row))
        _, meta = next(grep.buffer_data[buf])
        assert.are.same({}, meta.context)
        assert.are.equal(0, meta.expand_up)
        assert.are.equal(0, meta.expand_down)
    end)

    it("shrink_context is a no-op on a collapsed match", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:1:four" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)

        assert.is_false(grep.shrink_context(buf, match_row))
        local _, meta = next(grep.buffer_data[buf])
        assert.are.same({}, meta.context)
        assert.are.equal(0, meta.expand_up)
        assert.are.equal(0, meta.expand_down)
    end)

    it("shrink_context removes only rows not covered by another expanded match", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":4:1:four", path .. ":6:1:six" })
        table.insert(buffers, buf)

        local first_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 4
        end)
        assert.is_true(grep.expand_context(buf, first_match_row))
        -- Re-fetch second match row AFTER first expansion (buffer layout changed).
        local second_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 6
        end)
        assert.is_true(grep.expand_context(buf, second_match_row))

        -- Shrink match 4 by ±3: from ±3 to ±0 (collapse). Rows shared
        -- with match 6 (e.g. lnum 5, 6, 7) must NOT be deleted.
        first_match_row = row_for(buf, function(location)
            return location.kind == "match" and grep.buffer_data[buf][location.match_id].lnum == 4
        end)
        assert.is_true(grep.shrink_context(buf, first_match_row))

        local first_meta = nil
        for _, m in pairs(grep.buffer_data[buf]) do
            if m.lnum == 4 then
                first_meta = m
            end
        end
        assert.are.same({}, first_meta.context)
        assert.are.equal(0, first_meta.expand_up)
        assert.are.equal(0, first_meta.expand_down)

        -- Rows covered by match 6 (lnums 3–9) must still be shown.
        local shown_lnums = {}
        for row, location in pairs(grep.row_index[buf]) do
            local m = grep.buffer_data[buf][location.match_id]
            local lnum = location.kind == "match" and m.lnum or m.context[location.context_index].lnum
            shown_lnums[lnum] = true
        end
        assert.is.truthy(shown_lnums[3])
        assert.is.truthy(shown_lnums[5])
        assert.is.truthy(shown_lnums[6])
        assert.is.truthy(shown_lnums[7])
        assert.is.truthy(shown_lnums[9])
        -- Row 1 (only covered by match 4's old context) should be gone.
        assert.is_nil(shown_lnums[1])
    end)

    it("expand_all grows every match and collapse_all collapses every match", function()
        local path = write_fixture { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":3:1:three", path .. ":8:1:eight" })
        table.insert(buffers, buf)

        -- Expand all: both matches should grow.
        grep.expand_all(buf)
        local metas = vim.tbl_values(grep.buffer_data[buf])
        table.sort(metas, function(a, b)
            return a.lnum < b.lnum
        end)
        assert.is_true(#metas[1].context > 0)
        assert.is_true(#metas[2].context > 0)

        -- Collapse all: both matches should lose context.
        grep.collapse_all(buf)
        metas = vim.tbl_values(grep.buffer_data[buf])
        table.sort(metas, function(a, b)
            return a.lnum < b.lnum
        end)
        assert.are.same({}, metas[1].context)
        assert.are.same({}, metas[2].context)
        assert.are.equal(0, metas[1].expand_up)
        assert.are.equal(0, metas[1].expand_down)
        assert.are.equal(0, metas[2].expand_up)
        assert.are.equal(0, metas[2].expand_down)
    end)

    it("keeps same-line multi-match anchors as distinct rows and allows in-place edits", function()
        -- Two matches on the same file:lnum but different columns.
        -- Both must remain as distinct anchor rows — never deduped.
        local path = write_fixture { "local foo = bar.baz", "local qux = 1" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, {
            path .. ":1:1:local foo = bar.baz",
            path .. ":1:7:local foo = bar.baz",
        })
        table.insert(buffers, buf)

        -- expected_line_count must equal the actual buffer line count:
        -- 2 match anchors = 2.
        assert.are.equal(2, grep.expected_line_count[buf])
        assert.are.equal(grep.expected_line_count[buf], api.nvim_buf_line_count(buf))

        -- Both match anchors must be distinct rows with distinct extmarks.
        local match_rows = {}
        for row, location in pairs(grep.row_index[buf]) do
            if location.kind == "match" then
                match_rows[row] = location.match_id
            end
        end
        local row_count = 0
        local id_set = {}
        for _, id in pairs(match_rows) do
            row_count = row_count + 1
            id_set[id] = true
        end
        assert.are.equal(2, row_count, "two match anchors must occupy two distinct rows")
        assert.are.equal(2, vim.tbl_count(id_set), "two match anchors must have distinct extmark ids")

        -- An in-place text edit on one anchor must NOT trigger the
        -- structural-edit guard (line count is unchanged).
        local first_match_row = nil
        for row in pairs(match_rows) do
            if first_match_row == nil or row < first_match_row then
                first_match_row = row
            end
        end
        local expected = grep.expected_line_count[buf]
        api.nvim_buf_set_lines(buf, first_match_row, first_match_row + 1, false, { "local foo = qux.baz" })
        api.nvim_exec_autocmds("TextChanged", { buffer = buf })

        -- The edit is preserved (line count unchanged, guard not triggered).
        assert.are.equal(expected, api.nvim_buf_line_count(buf))
        assert.are.equal(
            "local foo = qux.baz",
            api.nvim_buf_get_lines(buf, first_match_row, first_match_row + 1, false)[1]
        )
        -- Context must not have been collapsed (no context existed, but
        -- the guard must not have fired and rebuilt the buffer).
        for _, meta in pairs(grep.buffer_data[buf]) do
            assert.are.same({}, meta.context)
        end
    end)

    it("reconciles stale grep text against disk on initial transform", function()
        local path = write_fixture { "one", "two-disk", "three" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":2:1:two-stale" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.are.equal("two-disk", api.nvim_buf_get_lines(buf, match_row, match_row + 1, false)[1])
        local _, meta = next(grep.buffer_data[buf])
        assert.are.equal("two-disk", meta.original_text)
    end)

    it("keeps parsed text when the source file is unreadable", function()
        local buf = make_grep_buffer("/nonexistent/path/file.lua", { "/nonexistent/path/file.lua:2:1:two-stale" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.are.equal("two-stale", api.nvim_buf_get_lines(buf, match_row, match_row + 1, false)[1])
        local _, meta = next(grep.buffer_data[buf])
        assert.are.equal("two-stale", meta.original_text)
    end)

    it("leaves matching grep text unchanged on initial transform", function()
        local path = write_fixture { "one", "two", "three" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":2:1:two" })
        table.insert(buffers, buf)
        local match_row = row_for(buf, function(location)
            return location.kind == "match"
        end)
        assert.are.equal("two", api.nvim_buf_get_lines(buf, match_row, match_row + 1, false)[1])
        local _, meta = next(grep.buffer_data[buf])
        assert.are.equal("two", meta.original_text)
    end)

    it("show_help exists and opens a floating window without error", function()
        local path = write_fixture { "one", "two" }
        table.insert(files, path)
        local buf = make_grep_buffer(path, { path .. ":2:1:two" })
        table.insert(buffers, buf)

        assert.is_true(type(grep.show_help) == "function")
        local win = grep.show_help(buf)
        assert.is_true(api.nvim_win_is_valid(win))
        api.nvim_win_close(win, true)
    end)
end)
