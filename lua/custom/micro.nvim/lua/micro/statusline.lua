local ns_id = vim.api.nvim_create_namespace "StatusLineNS"

local function get_hl_fg(groups)
    for _, group in ipairs(groups) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
        if ok and hl and type(hl.fg) == "number" then
            return string.format("#%06x", hl.fg)
        end
    end
    return "NONE"
end

local function get_hl_bg(groups)
    for _, group in ipairs(groups) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
        if ok and hl and type(hl.bg) == "number" then
            return string.format("#%06x", hl.bg)
        end
    end
    return "NONE"
end

local panel = require "micro.panel"

local M = {}

local defaults = {
    ignored = {
        names = {
            ["NvimTree_1"] = true,
            ["[Yazi]"] = true,
        },
        buftypes = {
            -- ["terminal"] = true,
            ["prompt"] = true,
            -- ["nofile"] = true,
        },
        filetypes = {
            ["snacks_dashboard"] = true,
            ["snacks_picker_list"] = true,
            ["snacks_picker_input"] = true,
            ["snacks_terminal"] = true,
            ["refer_input"] = true,
            ["refer_results"] = true,
        },
    },
    colors = {},
    diff = {
        symbols = { added = " ", modified = "󰝤 ", removed = " " },
    },
    lsp_errors = {
        symbols = { info = " ", warn = " ", error = " " },
    },
    border_style = { " ", "─", "", "", "", "", "", "" },
}
local config = defaults

function M.refresh_colors()
    local c = config.colors
    c.fg = get_hl_fg { "Normal" }
    c.bg = get_hl_bg { "StatusLine", "Normal" }
    c.red = get_hl_fg { "DiffDelete", "DiagnosticError", "GitSignsDelete", "Error" }
    c.orange = get_hl_fg { "DiffChange", "GitSignsChange", "Constant", "WarningMsg", "Number" }
    c.yellow = get_hl_fg { "DiagnosticWarn", "WarningMsg" }
    c.green = get_hl_fg { "DiffAdd", "DiagnosticOk", "GitSignsAdd", "String" }
    c.cyan = get_hl_fg { "DiagnosticHint", "Special", "Identifier" }
    c.blue = get_hl_fg { "Function", "Type", "Identifier" }
    c.violet = get_hl_fg { "Statement", "Keyword" }
    c.magenta = get_hl_fg { "Special", "Identifier", "PreProc" }
    c.darkblue = c.blue
end

function M.setup_highlights()
    M.refresh_colors()

    vim.api.nvim_set_hl(0, "StatusLine", { bg = "None", fg = "None" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "None", fg = "None" })

    vim.api.nvim_set_hl(0, "StatusLineFilename", { fg = config.colors.fg, bg = "None", bold = true })
    vim.api.nvim_set_hl(0, "StatusLineFilenameEdited", { fg = config.colors.yellow, bg = "None", bold = true })
    vim.api.nvim_set_hl(0, "StatusLineFilenameRO", { fg = config.colors.red, bg = "None", bold = true })

    vim.api.nvim_set_hl(0, "StatusLineGitBranch", { fg = config.colors.violet, bg = "None", bold = true })

    vim.api.nvim_set_hl(0, "StatusLineDiffAdd", { fg = config.colors.green, bg = "None" })
    vim.api.nvim_set_hl(0, "StatusLineDiffChange", { fg = config.colors.orange, bg = "None" })
    vim.api.nvim_set_hl(0, "StatusLineDiffDelete", { fg = config.colors.red, bg = "None" })

    vim.api.nvim_set_hl(0, "StatusLineDiagError", { fg = config.colors.red, bg = "None" })
    vim.api.nvim_set_hl(0, "StatusLineDiagWarn", { fg = config.colors.yellow, bg = "None" })
    vim.api.nvim_set_hl(0, "StatusLineDiagInfo", { fg = config.colors.cyan, bg = "None" })

    vim.api.nvim_set_hl(0, "StatusLineLspProgress", { fg = config.colors.green, bg = "None" })
end

function M.is_ignored(buf_id)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf_id), ":t")
    local buftype = vim.bo[buf_id].buftype
    local filetype = vim.bo[buf_id].filetype

    if vim.b[buf_id].micro_panel or config.ignored.names[name] then
        return true
    end
    if config.ignored.buftypes[buftype] then
        return true
    end
    if config.ignored.filetypes[filetype] then
        return true
    end
    if not vim.g.micro_statusline then
        return true
    end
    -- Per-buffer runtime toggle, exported via :Micro statusline enable/disable/toggle
    if vim.b[buf_id].micro_statusline_disabled then
        return true
    end
    return false
end

function M.enable(buf_id)
    buf_id = buf_id or vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_buf_del_var, buf_id, "micro_statusline_disabled")
    M.update()
end

function M.disable(buf_id)
    buf_id = buf_id or vim.api.nvim_get_current_buf()
    vim.b[buf_id].micro_statusline_disabled = true
    M.update()
end

function M.toggle(buf_id)
    buf_id = buf_id or vim.api.nvim_get_current_buf()
    if vim.b[buf_id].micro_statusline_disabled then
        M.enable(buf_id)
    else
        M.disable(buf_id)
    end
end

function M.get_mode_color()
    local m = vim.fn.mode()
    local c = config.colors
    local map = {
        n = c.blue,
        i = c.green,
        v = c.red,
        ["\22"] = c.red,
        V = c.red,
        c = c.magenta,
        no = c.red,
        s = c.orange,
        S = c.orange,
        ["\19"] = c.orange,
        ic = c.yellow,
        R = c.violet,
        Rv = c.violet,
        cv = c.red,
        ce = c.red,
        r = c.cyan,
        rm = c.cyan,
        ["r?"] = c.cyan,
        ["!"] = c.red,
        t = c.red,
    }
    return map[m] or c.blue
end

function M.get_git_branch(buf_id)
    local signs = vim.b[buf_id].gitsigns_status_dict
    local text = signs and ("  " .. (signs.head or "") .. " ") or ""
    return { { text = text, group = "StatusLineGitBranch" } }
end

function M.get_git_diff(buf_id)
    local signs = vim.b[buf_id].gitsigns_status_dict
    if not signs then
        return {}
    end

    local diff = config.diff
    local parts = { { text = " ", group = "None" } }

    if (signs.added or 0) > 0 then
        table.insert(parts, { text = diff.symbols.added .. signs.added .. " ", group = "StatusLineDiffAdd" })
    end
    if (signs.changed or 0) > 0 then
        table.insert(parts, { text = diff.symbols.modified .. signs.changed .. " ", group = "StatusLineDiffChange" })
    end
    if (signs.removed or 0) > 0 then
        table.insert(parts, { text = diff.symbols.removed .. signs.removed .. " ", group = "StatusLineDiffDelete" })
    end

    return parts
end

function M.get_diagnostics(buf_id)
    local count = vim.diagnostic.count(buf_id)
    local parts = { { text = " ", group = "None" } }
    local sym = config.lsp_errors.symbols

    if (count[vim.diagnostic.severity.HINT] or 0) > 0 then
        table.insert(parts, { text = sym.info .. count[4] .. " ", group = "StatusLineDiagInfo" })
    end
    if (count[vim.diagnostic.severity.WARN] or 0) > 0 then
        table.insert(parts, { text = sym.warn .. count[2] .. " ", group = "StatusLineDiagWarn" })
    end
    if (count[vim.diagnostic.severity.ERROR] or 0) > 0 then
        table.insert(parts, { text = sym.error .. count[1] .. " ", group = "StatusLineDiagError" })
    end

    return parts
end

local client_progress = {}

function M.get_lsp_status(buf_id)
    local clients = vim.lsp.get_clients { bufnr = buf_id }
    local parts = {}
    for _, client in ipairs(clients) do
        local p = client_progress[client.id]
        local text = client.name
        if p then
            if p.title then
                text = text .. ": " .. p.title
            end
            if p.message then
                text = text .. " " .. p.message
            end
            if p.percentage then
                text = text .. " " .. p.percentage .. "%%"
            end
        end
        table.insert(parts, { text = " " .. text .. " ", group = "StatusLineLspProgress" })
    end
    return parts
end

function M.get_file_info(buf_id, max_width)
    local full_path = vim.api.nvim_buf_get_name(buf_id)
    local extension = vim.fn.fnamemodify(full_path, ":e")
    local tail = vim.fn.fnamemodify(full_path, ":t")

    local icon_symbol, icon_hl_group = require("nvim-web-devicons").get_icon(tail, extension, { default = true })
    local icon = { text = " " .. icon_symbol .. " ", group = icon_hl_group }

    local state_suffix = ""
    local name_group = "StatusLineFilename"
    if vim.bo[buf_id].modified then
        state_suffix = "󰏫 "
        name_group = "StatusLineFilenameEdited"
    elseif vim.bo[buf_id].readonly then
        state_suffix = "󰏮 "
        name_group = "StatusLineFilenameRO"
    end

    local padding_width = 2 + vim.fn.strdisplaywidth(state_suffix)
    local path_budget = (max_width or 999) - padding_width

    local filename
    if full_path == "" then
        filename = "[No Name]"
    else
        -- Level 0: full relative path
        local rel = vim.fn.fnamemodify(full_path, ":.")
        if vim.fn.strdisplaywidth(rel) <= path_budget then
            filename = rel
        else
            -- Level 1: pathshorten (e.g. lua/m/s/file.lua)
            local shortened = vim.fn.pathshorten(rel)
            if vim.fn.strdisplaywidth(shortened) <= path_budget then
                filename = shortened
            else
                -- Level 2: tail only (e.g. file.lua)
                if vim.fn.strdisplaywidth(tail) <= path_budget then
                    filename = tail
                else
                    -- Level 3: truncate tail with ellipsis
                    local truncated = vim.fn.strcharpart(tail, 0, math.max(path_budget - 1, 1)) .. "…"
                    filename = truncated
                end
            end
        end
    end

    local name = { text = " " .. filename .. " " .. state_suffix, group = name_group }

    return {
        icon = icon,
        name = name,
    }
end

function M.generate_content(win_id, buf_id, width)
    local function get_components_width(list)
        local w = 0
        for _, c in ipairs(list) do
            w = w + vim.fn.strdisplaywidth(c.text)
        end
        return w
    end

    -- A. Fetch all auxiliary components early
    local diffs = M.get_git_diff(buf_id)
    local lsp_status = M.get_lsp_status(buf_id)
    local diags = M.get_diagnostics(buf_id)
    local branch = M.get_git_branch(buf_id)

    -- B. Adaptive component hiding
    local icon_width = 3
    local min_path_width = 20

    local function available_for_path()
        return width
            - icon_width
            - get_components_width(diffs)
            - get_components_width(lsp_status)
            - get_components_width(diags)
            - get_components_width(branch)
    end

    if available_for_path() < min_path_width then
        lsp_status = {}
    end
    if available_for_path() < min_path_width then
        branch = {}
    end
    if available_for_path() < min_path_width then
        diffs = {}
    end

    local path_budget = available_for_path()

    -- C. Build components with adaptive file info
    local left_components = {}
    local right_components = {}

    local file = M.get_file_info(buf_id, path_budget)
    table.insert(left_components, file.icon)
    table.insert(left_components, file.name)

    for _, d in ipairs(diffs) do
        table.insert(left_components, d)
    end

    for _, s in ipairs(lsp_status) do
        table.insert(right_components, s)
    end
    for _, d in ipairs(diags) do
        table.insert(right_components, d)
    end
    for _, b in ipairs(branch) do
        table.insert(right_components, b)
    end

    -- D. Calculate Spacer
    local left_len = get_components_width(left_components)
    local right_len = get_components_width(right_components)

    local space_len = width - left_len - right_len
    local spacer_text = string.rep(" ", math.max(space_len, 0))

    -- E. Assemble and Track Highlights
    local full_text = ""
    local highlights = {}

    local function add_components(list)
        for _, comp in ipairs(list) do
            local start_pos = #full_text
            full_text = full_text .. comp.text
            local end_pos = #full_text
            if comp.group then
                table.insert(highlights, { group = comp.group, start = start_pos, finish = end_pos })
            end
        end
    end

    add_components(left_components)
    full_text = full_text .. spacer_text
    add_components(right_components)

    return full_text, highlights
end

function M.render_window(parent_win, buf_id)
    local key = "statusline:" .. parent_win
    if M.is_ignored(buf_id) or vim.api.nvim_win_get_config(parent_win).relative ~= "" then
        panel.close(key)
        return
    end

    local width = vim.api.nvim_win_get_width(parent_win)
    local height = vim.api.nvim_win_get_height(parent_win)
    local is_active = vim.api.nvim_get_current_win() == parent_win

    local row = height - 1

    local content, highlights = M.generate_content(parent_win, buf_id, width)

    local opts = {
        relative = "win",
        win = parent_win,
        width = width,
        height = 1,
        row = row,
        col = 0,
        border = config.border_style,
        style = "minimal",
        focusable = false,
        zindex = 10,
    }

    local status_win, status_buf = panel.open(key, { content }, opts, { parent = parent_win })

    vim.api.nvim_buf_clear_namespace(status_buf, ns_id, 0, -1)
    for _, hl in ipairs(highlights) do
        vim.hl.range(status_buf, ns_id, hl.group, { 0, hl.start }, { 0, hl.finish })
    end

    local border_group = "Comment"
    if is_active then
        local mode = vim.api.nvim_get_mode().mode
        local mode_name = mode
        if mode == "\22" then
            mode_name = "VBlock"
        end
        if mode == "\19" then
            mode_name = "SBlock"
        end
        -- Highlight group names may only contain [A-Za-z0-9_]; modes like "r?"
        -- (prompt shown by e.g. neogit's blocking confirm dialog) or "noCTRL-V"
        -- contain illegal characters, so sanitize the suffix.
        mode_name = mode_name:gsub("[^%w_]", "")

        local hl_name = "StatusBorderActive" .. mode_name
        vim.api.nvim_set_hl(0, hl_name, { fg = M.get_mode_color() })
        border_group = hl_name
    end

    vim.api.nvim_set_option_value("winhighlight", "Normal:Normal,FloatBorder:" .. border_group, { win = status_win })
end

function M.update()
    vim.schedule(function()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_is_valid(win) then
                pcall(M.render_window, win, vim.api.nvim_win_get_buf(win))
            end
        end
    end)
end

function M.autoscroll()
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(win).relative ~= "" then
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    if M.is_ignored(buf) then
        return
    end

    local mode = vim.fn.mode()
    if mode == "i" or mode == "ic" or mode == "ix" then
        return
    end

    local current_line = vim.fn.line "."
    local last_line = vim.fn.line "$"

    if current_line == last_line then
        local win_height = vim.api.nvim_win_get_height(win)
        local cursor_win_line = vim.fn.winline()
        if math.abs(cursor_win_line - win_height) <= 1 then
            vim.cmd "normal! \5"
        end
    end
end

-- Export subcommands for the global :Micro command; the "statusline" node nests
-- enable/disable/toggle as sub-subcommands (operate on the current buffer)
M.subcommands = {
    statusline = {
        enable = function()
            M.enable()
        end,
        disable = function()
            M.disable()
        end,
        toggle = function()
            M.toggle()
        end,
    },
}

function M.setup(opts)
    config = vim.tbl_deep_extend("force", defaults, opts or {})

    vim.opt.statusline = " "
    vim.opt.scrolloff = 1
    vim.g.micro_statusline = true
    M.setup_highlights()

    local grp = vim.api.nvim_create_augroup("CustomStatusLine", { clear = true })

    vim.api.nvim_create_autocmd(
        { "WinEnter", "WinClosed", "VimResized", "WinScrolled", "BufEnter", "CursorHold", "ModeChanged" },
        { group = grp, callback = M.update }
    )

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { group = grp, callback = M.autoscroll })

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = grp,
        callback = function()
            M.setup_highlights()
            M.update()
        end,
    })

    vim.api.nvim_create_autocmd("LspProgress", {
        group = grp,
        callback = function(ev)
            local client_id = ev.data.client_id
            local value = ev.data.params.value
            if not client_progress[client_id] then
                client_progress[client_id] = {}
            end
            local p = client_progress[client_id]
            if value.kind == "begin" then
                p.title = value.title
                p.message = value.message
                p.percentage = value.percentage
            elseif value.kind == "report" then
                if value.title then
                    p.title = value.title
                end
                if value.message then
                    p.message = value.message
                end
                if value.percentage then
                    p.percentage = value.percentage
                end
            elseif value.kind == "end" then
                client_progress[client_id] = nil
            end
            M.update()
        end,
    })
end

return M
