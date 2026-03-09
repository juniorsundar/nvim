local M = {}

local api = vim.api

local function setup_highlights()
    local hls = {
        KeymapMode = { link = "Keyword" },
        KeymapKey = { link = "String" },
        KeymapSep = { link = "Operator" },
        KeymapSource = { link = "Comment" },
        KeymapDesc = { link = "Normal" },
        KeymapContext = { link = "Title" },
        KeymapDivider = { link = "Comment" },
    }
    for group, val in pairs(hls) do
        api.nvim_set_hl(0, group, { link = val.link, default = true })
    end
end

setup_highlights()

local ns_id = api.nvim_create_namespace "buffers_keymap"

-- buffer_data[bufnr][extmark_id] = { mode, lhs, desc, callback, rhs, buffer_local, source_file, source_line, is_context_action, action_fn, context_target }
M.buffer_data = {}

-- Saved invocation context (the buffer/window that was active when :Keymap was called)
M.source_bufnr = nil
M.source_winid = nil

---Detect what is under the cursor in the given buffer/position.
---@param bufnr integer
---@param cursor integer[] {row, col} (0-indexed row)
---@return table { type: string, target: any }
local function detect_context(bufnr, cursor)
    local row = cursor[1]

    local diags = vim.diagnostic.get(bufnr, { lnum = row })
    if diags and #diags > 0 then
        return { type = "diagnostic", target = diags[1] }
    end

    local cfile = vim.fn.expand "<cfile>"
    if cfile and cfile ~= "" then
        local readable = vim.fn.filereadable(cfile) == 1 or vim.fn.filereadable(vim.fn.fnamemodify(cfile, ":p")) == 1
        if readable then
            return { type = "file", target = vim.fn.fnamemodify(cfile, ":p") }
        end
    end

    local cword = vim.fn.expand "<cWORD>"
    if cword and cword:match "^https?://" then
        return { type = "url", target = cword }
    end

    local clients = vim.lsp.get_clients { bufnr = bufnr }
    if #clients > 0 then
        local word = vim.fn.expand "<cword>"
        if word and word ~= "" then
            return { type = "lsp_symbol", target = word }
        end
    end

    return { type = "general", target = nil }
end

-- Context action definitions (Embark-style action maps per target type)
-- Can extend M.context_actions in their config via M.setup()
M.context_actions = {
    lsp_symbol = {
        {
            desc = "Go to definition",
            fn = function()
                vim.lsp.buf.definition()
            end,
        },
        {
            desc = "Go to references",
            fn = function()
                vim.lsp.buf.references()
            end,
        },
        {
            desc = "Go to implementation",
            fn = function()
                vim.lsp.buf.implementation()
            end,
        },
        {
            desc = "Go to declaration",
            fn = function()
                vim.lsp.buf.declaration()
            end,
        },
        {
            desc = "Rename symbol",
            fn = function()
                vim.lsp.buf.rename()
            end,
        },
        {
            desc = "Code action",
            fn = function()
                vim.lsp.buf.code_action()
            end,
        },
        {
            desc = "Hover documentation",
            fn = function()
                vim.lsp.buf.hover()
            end,
        },
        {
            desc = "Signature help",
            fn = function()
                vim.lsp.buf.signature_help()
            end,
        },
    },
    file = {
        {
            desc = "Open file",
            fn = function(t)
                vim.cmd.edit(t)
            end,
        },
        {
            desc = "Open in split",
            fn = function(t)
                vim.cmd.split(t)
            end,
        },
        {
            desc = "Open in vsplit",
            fn = function(t)
                vim.cmd.vsplit(t)
            end,
        },
        {
            desc = "Open in new tab",
            fn = function(t)
                vim.cmd.tabedit(t)
            end,
        },
        {
            desc = "Copy path to clipboard",
            fn = function(t)
                vim.fn.setreg("+", t)
                vim.notify("Copied: " .. t)
            end,
        },
    },
    url = {
        {
            desc = "Open URL in browser",
            fn = function(t)
                vim.ui.open(t)
            end,
        },
        {
            desc = "Copy URL to clipboard",
            fn = function(t)
                vim.fn.setreg("+", t)
                vim.notify("Copied: " .. t)
            end,
        },
    },
    diagnostic = {
        {
            desc = "Show diagnostic float",
            fn = function()
                vim.diagnostic.open_float()
            end,
        },
        {
            desc = "Go to next diagnostic",
            fn = function()
                vim.diagnostic.jump { count = 1 }
            end,
        },
        {
            desc = "Go to prev diagnostic",
            fn = function()
                vim.diagnostic.jump { count = -1 }
            end,
        },
        {
            desc = "Add to quickfix list",
            fn = function()
                vim.diagnostic.setqflist()
            end,
        },
        {
            desc = "Code action",
            fn = function()
                vim.lsp.buf.code_action()
            end,
        },
    },
    general = {},
}

---Collect and merge keymaps for the given mode from global + buffer-local.
---@param opts { mode: string, source_bufnr: integer }
---@return table[] list of keymap entry tables
local function collect_keymaps(opts)
    local mode = opts.mode or "n"
    local source_bufnr = opts.source_bufnr or api.nvim_get_current_buf()

    local global_maps = api.nvim_get_keymap(mode)
    local buffer_maps = api.nvim_buf_get_keymap(source_bufnr, mode)

    -- Index buffer-local maps by lhs so we can override globals
    local buf_lhs_set = {}
    for _, m in ipairs(buffer_maps) do
        buf_lhs_set[m.lhs] = true
    end

    -- Merge: buffer-local first, then globals that aren't shadowed
    local merged = {}
    for _, m in ipairs(buffer_maps) do
        table.insert(merged, vim.tbl_extend("force", m, { buffer_local = true }))
    end
    for _, m in ipairs(global_maps) do
        if not buf_lhs_set[m.lhs] then
            table.insert(merged, vim.tbl_extend("force", m, { buffer_local = false }))
        end
    end

    local filtered = vim.tbl_filter(function(m)
        return m.desc and m.desc ~= ""
    end, merged)

    table.sort(filtered, function(a, b)
        return (a.desc or "") < (b.desc or "")
    end)

    return filtered
end

---Try to resolve the source file + line for a Lua callback.
---@param cb function
---@return string|nil filepath, integer|nil lineno
local function resolve_callback_source(cb)
    if type(cb) ~= "function" then
        return nil, nil
    end
    local info = debug.getinfo(cb, "S")
    if not info then
        return nil, nil
    end
    local src = info.source
    if not src then
        return nil, nil
    end

    if src:sub(1, 1) == "@" then
        local path = src:sub(2)
        return path, info.linedefined
    end
    return nil, nil
end

-- Filetypes that belong to ephemeral picker/prompt buffers.
-- If create_buffer() is invoked from one of these, we close the picker first
-- so its WinLeave teardown doesn't destroy our freshly-opened keymap buffer.
local EPHEMERAL_FILETYPES = {
    refer_input = true,
    refer_results = true,
}

---Create and open the keymap buffer.
---@param opts { mode: string|nil, source_bufnr: integer|nil, source_winid: integer|nil, picker_keymaps: table|nil }
function M.create_buffer(opts)
    opts = opts or {}
    local mode = opts.mode or "n"
    local source_bufnr = opts.source_bufnr or api.nvim_get_current_buf()
    local source_winid = opts.source_winid or api.nvim_get_current_win()
    local picker_keymaps = opts.picker_keymaps or nil

    if EPHEMERAL_FILETYPES[vim.bo[source_bufnr].filetype] then
        local picker_keymaps = {}
        for _, m in ipairs { "i", "n" } do
            local maps = api.nvim_buf_get_keymap(source_bufnr, m)
            for _, km in ipairs(maps) do
                if km.desc and km.desc ~= "" then
                    local file, line = resolve_callback_source(km.callback)
                    table.insert(picker_keymaps, {
                        mode = m,
                        lhs = km.lhs or "",
                        desc = km.desc or "",
                        rhs = km.rhs,
                        callback = km.callback,
                        noremap = km.noremap == 1,
                        buffer_local = true,
                        source_file = file,
                        source_line = line,
                    })
                end
            end
        end
        table.sort(picker_keymaps, function(a, b)
            return (a.desc or "") < (b.desc or "")
        end)

        vim.cmd "stopinsert"
        pcall(api.nvim_win_close, source_winid, true)
        vim.schedule(function()
            M.create_buffer {
                mode = mode,
                source_bufnr = api.nvim_get_current_buf(),
                source_winid = api.nvim_get_current_win(),
                picker_keymaps = picker_keymaps,
            }
        end)
        return
    end

    M.source_bufnr = source_bufnr
    M.source_winid = source_winid
    M.invocation_mode = mode

    local cursor = api.nvim_win_get_cursor(source_winid)
    local cursor_0 = { cursor[1] - 1, cursor[2] }
    local ctx = detect_context(source_bufnr, cursor_0)
    M.invocation_context = ctx

    local keymaps = collect_keymaps { mode = mode, source_bufnr = source_bufnr }

    local ctx_actions = (ctx.type ~= "general") and M.context_actions[ctx.type] or nil

    local lines = {}

    -- Header
    local mode_label = ({
        n = "Normal",
        i = "Insert",
        v = "Visual",
        x = "Visual (block)",
        s = "Select",
        o = "Operator-pending",
        c = "Command",
        t = "Terminal",
    })[mode] or mode

    local ctx_label = ctx.type ~= "general"
            and string.format(" | Context: %s", ctx.type:gsub("_", " "):gsub("^%l", string.upper))
        or ""

    local header = {
        string.format("# KEYMAP BUFFER  [%s mode%s]", mode_label, ctx_label),
        "# ------------------",
        "# <CR>        -> Execute keymap / action",
        "# <C-c><C-d>  -> Jump to keymap definition",
        "# q / <Esc>   -> Close",
        "",
    }
    for _, l in ipairs(header) do
        table.insert(lines, l)
    end

    local header_offset = #header

    -- Context actions section (if any)
    local context_section_start = nil
    local context_section_count = 0
    if ctx_actions and #ctx_actions > 0 then
        table.insert(lines, string.format("## Context Actions (%s)", ctx.type:gsub("_", " ")))
        table.insert(lines, "")
        context_section_start = #lines - 1 -- 1-indexed line of divider
        header_offset = #lines

        for _, act in ipairs(ctx_actions) do
            table.insert(lines, act.desc)
            context_section_count = context_section_count + 1
        end

        table.insert(lines, "")
        table.insert(lines, "## All Keymaps")
        table.insert(lines, "")
        header_offset = #lines
    end

    -- Picker keymaps section (only present when invoked from a picker buffer)
    if picker_keymaps and #picker_keymaps > 0 then
        table.insert(lines, "## Picker Keymaps")
        table.insert(lines, "")
        header_offset = #lines
        for _, km in ipairs(picker_keymaps) do
            table.insert(lines, km.desc)
        end
        table.insert(lines, "")
        table.insert(lines, "## All Keymaps")
        table.insert(lines, "")
        header_offset = #lines
    end

    for _, km in ipairs(keymaps) do
        table.insert(lines, km.desc)
    end

    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    M.buffer_data[buf] = {}

    if ctx_actions and #ctx_actions > 0 then
        local ctx_line_start = 0
        for i, l in ipairs(lines) do
            if l == string.format("## Context Actions (%s)", ctx.type:gsub("_", " ")) then
                ctx_line_start = i + 1
                break
            end
        end

        for idx, act in ipairs(ctx_actions) do
            local row = ctx_line_start + idx - 1 -- 0-indexed
            local eid = api.nvim_buf_set_extmark(buf, ns_id, row, 0, {})
            M.buffer_data[buf][eid] = {
                is_context_action = true,
                action_fn = act.fn,
                context_target = ctx.target,
                desc = act.desc,
                mode = mode,
                lhs = "",
                buffer_local = false,
            }
        end
    end

    -- Store metadata for picker keymap lines
    if picker_keymaps and #picker_keymaps > 0 then
        local pk_line_start = 0
        for i, l in ipairs(lines) do
            if l == "## Picker Keymaps" then
                pk_line_start = i + 1
                break
            end
        end

        for idx, km in ipairs(picker_keymaps) do
            local row = pk_line_start + idx - 1
            local eid = api.nvim_buf_set_extmark(buf, ns_id, row, 0, {})
            M.buffer_data[buf][eid] = {
                is_context_action = false,
                mode = km.mode or "i",
                lhs = km.lhs or "",
                desc = km.desc or "",
                rhs = km.rhs,
                callback = km.callback,
                noremap = km.noremap,
                buffer_local = true,
                source_file = km.source_file,
                source_line = km.source_line,
            }
        end
    end

    -- Store metadata for regular keymap lines
    -- Regular keymaps start at header_offset (0-indexed)
    for i, km in ipairs(keymaps) do
        local row = header_offset + i - 1 -- 0-indexed
        local file, line = resolve_callback_source(km.callback)
        local eid = api.nvim_buf_set_extmark(buf, ns_id, row, 0, {})
        M.buffer_data[buf][eid] = {
            is_context_action = false,
            mode = km.mode or mode,
            lhs = km.lhs or "",
            desc = km.desc or "",
            rhs = km.rhs,
            callback = km.callback,
            noremap = km.noremap == 1,
            buffer_local = km.buffer_local or false,
            source_file = file,
            source_line = line,
        }
    end

    vim.bo[buf].filetype = "keymap"
    vim.cmd.buffer(buf)
end

-- Highlight buffer (called from ftplugin after filetype is set)
function M.highlight_buffer(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    if vim.b[bufnr].keymap_processed then
        return
    end
    vim.b[bufnr].keymap_processed = true
    M.refresh_virt_text(bufnr)
end

-- Virtual text rendering
function M.refresh_virt_text(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()

    local extmarks = api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, { details = true })
    local buf_data = M.buffer_data[bufnr] or {}

    for _, extmark in ipairs(extmarks) do
        local id = extmark[1]
        local row = extmark[2]
        local col = extmark[3]

        local meta = buf_data[id]
        if not meta then
            goto continue
        end

        if meta.is_context_action then
            -- Context actions: show a ★ badge
            api.nvim_buf_set_extmark(bufnr, ns_id, row, col, {
                id = id,
                virt_text = {
                    { "★ ", "KeymapContext" },
                },
                virt_text_pos = "inline",
                hl_mode = "combine",
            })
        else
            -- Regular keymaps: show [mode] lhs :
            local mode_str = meta.mode or "n"
            local lhs_str = meta.lhs or ""
            local scope_str = meta.buffer_local and " [buf]" or ""

            local virt_chunks = {
                { "[", "KeymapSep" },
                { mode_str, "KeymapMode" },
                { "] ", "KeymapSep" },
                { lhs_str, "KeymapKey" },
                { scope_str, "KeymapSource" },
                { " : ", "KeymapSep" },
            }

            api.nvim_buf_set_extmark(bufnr, ns_id, row, col, {
                id = id,
                virt_text = virt_chunks,
                virt_text_pos = "inline",
                hl_mode = "combine",
            })
        end

        ::continue::
    end
end

-- Execute keymap / action
function M.execute_keymap()
    local bufnr = api.nvim_get_current_buf()
    local row = api.nvim_win_get_cursor(0)[1] - 1

    local extmarks = api.nvim_buf_get_extmarks(bufnr, ns_id, { row, 0 }, { row, -1 }, { limit = 1 })
    if #extmarks == 0 then
        vim.notify("No keymap on this line", vim.log.levels.WARN)
        return
    end

    local id = extmarks[1][1]
    local meta = (M.buffer_data[bufnr] or {})[id]
    if not meta then
        vim.notify("No metadata for this keymap", vim.log.levels.WARN)
        return
    end

    api.nvim_buf_delete(bufnr, { force = true })

    if M.source_winid and api.nvim_win_is_valid(M.source_winid) then
        api.nvim_set_current_win(M.source_winid)
    end

    if meta.is_context_action then
        -- Context action: call the function with the target (if any)
        if meta.action_fn then
            meta.action_fn(meta.context_target)
        end
    else
        -- Regular keymap: prefer calling the Lua callback directly
        if meta.callback and type(meta.callback) == "function" then
            meta.callback()
        elseif meta.lhs and meta.lhs ~= "" then
            local keys = api.nvim_replace_termcodes(meta.lhs, true, true, true)
            api.nvim_feedkeys(keys, meta.mode or "n", false)
        else
            vim.notify("Cannot execute: no callback or lhs for this keymap", vim.log.levels.WARN)
        end
    end
end

-- Jump to keymap definition
function M.nav_to_definition()
    local bufnr = api.nvim_get_current_buf()
    local row = api.nvim_win_get_cursor(0)[1] - 1

    local extmarks = api.nvim_buf_get_extmarks(bufnr, ns_id, { row, 0 }, { row, -1 }, { limit = 1 })
    if #extmarks == 0 then
        vim.notify("No keymap on this line", vim.log.levels.WARN)
        return
    end

    local id = extmarks[1][1]
    local meta = (M.buffer_data[bufnr] or {})[id]
    if not meta then
        return
    end

    if meta.is_context_action then
        vim.notify("Context actions are built-in; no source file to jump to.", vim.log.levels.INFO)
        return
    end

    if not meta.source_file then
        vim.notify(
            string.format("No source location available for '%s' (may be a string mapping or built-in)", meta.lhs),
            vim.log.levels.WARN
        )
        return
    end

    local filepath = meta.source_file
    local lineno = meta.source_line or 1

    api.nvim_buf_delete(bufnr, { force = true })

    if vim.fn.filereadable(filepath) == 1 then
        vim.cmd.edit(filepath)
        pcall(api.nvim_win_set_cursor, 0, { lineno, 0 })
        vim.cmd "normal! zz"
    else
        vim.notify("Source file not readable: " .. filepath, vim.log.levels.ERROR)
    end
end

---@param opts { context_actions: table|nil }
function M.setup(opts)
    opts = opts or {}
    if opts.context_actions then
        for ctx_type, actions in pairs(opts.context_actions) do
            M.context_actions[ctx_type] = M.context_actions[ctx_type] or {}
            for _, act in ipairs(actions) do
                table.insert(M.context_actions[ctx_type], act)
            end
        end
    end
end

return M
