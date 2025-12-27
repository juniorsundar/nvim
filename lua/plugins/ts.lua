local M = {}

M.config = {
    highlights = {
        source_node = "Visual",
        tree_node = "PmenuSel",
        tree_win_hl = "Normal:NormalFloat",
    },
    icons = {
        branch_mid = "├── ",
        branch_end = "└── ",
        indent_mid = "│   ",
        indent_end = "    ",
    },
    window = {
        border = "solid",
        width_padding = 2,
    },
    keymaps = {
        enable = true,
        toggle = { desc = "show treesitter context", key = "<leader>Tt" },
        next = { desc = "next treesitter sibling", key = "<leader>T]" },
        prev = { desc = "prev treesitter sibling", key = "<leader>T[" },
        parent = { desc = "parent treesitter node", key = "<leader>Tk" },
        child = { desc = "child treesitter node", key = "<leader>Tj" },
    },
}

local state = {
    tree_win = nil,
    sticky_node = nil,
    is_navigating = false,
    ns_nav = vim.api.nvim_create_namespace "ts_nav",
    tree_grp = vim.api.nvim_create_augroup("TSTreeDisplay", { clear = true }),
}

local function clear_highlights()
    vim.api.nvim_buf_clear_namespace(0, state.ns_nav, 0, -1)
end

local function close_tree_win()
    if state.tree_win and vim.api.nvim_win_is_valid(state.tree_win) then
        vim.api.nvim_win_close(state.tree_win, true)
    end
    state.tree_win = nil
    clear_highlights()
    vim.api.nvim_clear_autocmds { group = state.tree_grp }
end

local function dive_into_block(node)
    if not node then
        return nil
    end
    while node do
        if node:type() == "block" or node:type() == "statement_block" then
            local found_child = false
            local count = node:child_count()
            for i = 0, count - 1 do
                local child = node:child(i)
                if child:named() then
                    node = child
                    found_child = true
                    break
                end
            end
            if not found_child then
                break
            end
        else
            break
        end
    end
    return node
end

local function get_master_node()
    local node = vim.treesitter.get_node()
    return dive_into_block(node)
end

local function get_sticky_node()
    if not state.sticky_node then
        return nil
    end
    local ok, sr, sc = pcall(function()
        return state.sticky_node:start()
    end)
    if not ok then
        state.sticky_node = nil
        return nil
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cr, cc = cursor[1] - 1, cursor[2]
    if sr ~= cr or sc ~= cc then
        state.sticky_node = nil
        return nil
    end
    return state.sticky_node
end

local function get_nav_node()
    return get_sticky_node() or get_master_node()
end

local function highlight_source_node(target_node)
    clear_highlights()
    if target_node then
        local start_row, start_col, end_row, end_col = target_node:range()
        vim.api.nvim_buf_set_extmark(0, state.ns_nav, start_row, start_col, {
            end_row = end_row,
            end_col = end_col,
            hl_group = M.config.highlights.source_node,
            priority = 100,
        })
    end
end

M.ts_tree_display = function()
    local node = get_nav_node()

    if not node then
        if not state.is_navigating then
            vim.notify("no treesitter node found", vim.log.levels.WARN)
        end
        if state.tree_win and not state.is_navigating then
            close_tree_win()
        end
        return
    end

    highlight_source_node(node)

    local parent = node:parent()
    local root_of_view = parent or node

    local lines = {}
    local highlights = {}
    local conf = M.config

    table.insert(lines, root_of_view:type())
    if not parent then
        table.insert(highlights, { #lines - 1, conf.highlights.tree_node })
    end

    local children = {}
    for i = 0, root_of_view:child_count() - 1 do
        local child = root_of_view:child(i)
        if child:named() then
            table.insert(children, child)
        end
    end

    for i, child in ipairs(children) do
        local is_last = (i == #children)
        local marker = is_last and conf.icons.branch_end or conf.icons.branch_mid
        local is_target = (child:id() == node:id())

        table.insert(lines, marker .. child:type())

        if is_target then
            table.insert(highlights, { #lines - 1, conf.highlights.tree_node })

            local indent = is_last and conf.icons.indent_end or conf.icons.indent_mid
            local grandchildren = {}
            for j = 0, child:child_count() - 1 do
                local grandchild = child:child(j)
                if grandchild:named() then
                    table.insert(grandchildren, grandchild)
                end
            end
            for j, grandchild in ipairs(grandchildren) do
                local g_is_last = (j == #grandchildren)
                local g_marker = g_is_last and conf.icons.branch_end or conf.icons.branch_mid
                table.insert(lines, indent .. g_marker .. grandchild:type())
            end
        end
    end

    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, #line)
    end

    local opts = {
        relative = "win",
        anchor = "NE",
        width = width + conf.window.width_padding,
        height = #lines,
        col = vim.api.nvim_win_get_width(0),
        row = 0,
        style = "minimal",
        border = conf.window.border,
    }

    local buf
    if state.tree_win and vim.api.nvim_win_is_valid(state.tree_win) then
        buf = vim.api.nvim_win_get_buf(state.tree_win)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_win_set_config(state.tree_win, opts)
    else
        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].bufhidden = "wipe"

        state.tree_win = vim.api.nvim_open_win(buf, false, opts)
        vim.api.nvim_set_option_value("winhl", conf.highlights.tree_win_hl, { win = state.tree_win })

        vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
            group = state.tree_grp,
            buffer = 0,
            callback = function(ev)
                if state.is_navigating then
                    return
                end
                if ev.event == "CursorMoved" and get_sticky_node() then
                    return
                end
                close_tree_win()
            end,
        })
    end

    local popup_ns = vim.api.nvim_create_namespace "ts_tree_popup"
    vim.api.nvim_buf_clear_namespace(buf, popup_ns, 0, -1)
    for _, hl in ipairs(highlights) do
        vim.hl.range(buf, popup_ns, hl[2], { hl[1], 0 }, { hl[1], -1 })
    end
end

local function update_nav(target_node)
    if target_node then
        local r, c = target_node:start()
        state.is_navigating = true
        vim.api.nvim_win_set_cursor(0, { r + 1, c })
        state.sticky_node = target_node
        highlight_source_node(target_node)
        if state.tree_win and vim.api.nvim_win_is_valid(state.tree_win) then
            M.ts_tree_display()
        end
        state.is_navigating = false
    end
end

M.goto_parent = function()
    local node = get_nav_node()
    if not node then
        return
    end

    local start_row, start_col = node:start()
    local parent = node:parent()

    while parent do
        local p_row, p_col = parent:start()
        if p_row ~= start_row or p_col ~= start_col then
            update_nav(parent)
            return
        end
        parent = parent:parent()
    end
end

local function find_first_child_jump(node, root_start_row, root_start_col)
    local count = node:child_count()
    for i = 0, count - 1 do
        local child = node:child(i)
        if child:named() then
            local r, c = child:start()
            if r ~= root_start_row or c ~= root_start_col then
                return child
            else
                local found = find_first_child_jump(child, root_start_row, root_start_col)
                if found then
                    return found
                end
            end
        end
    end
    return nil
end

M.goto_child = function()
    local node = get_nav_node()
    if not node then
        return
    end

    local n_row, n_col = node:start()
    local target = find_first_child_jump(node, n_row, n_col)

    if target then
        target = dive_into_block(target)
        update_nav(target)
    end
end

M.goto_next = function()
    local node = get_nav_node()
    if not node then
        return
    end

    local next = node:next_named_sibling()
    if next then
        next = dive_into_block(next)
        update_nav(next)
    end
end

M.goto_prev = function()
    local node = get_nav_node()
    if not node then
        return
    end

    local prev = node:prev_named_sibling()
    if prev then
        prev = dive_into_block(prev)
        update_nav(prev)
    end
end

M.setup = function(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    if M.config.keymaps.enable then
        local km = M.config.keymaps
        local set = function(key, func, desc)
            if key then
                vim.keymap.set({ "n", "v" }, key, func, { desc = desc })
            end
        end

        set(km.toggle.key, M.ts_tree_display, km.toggle.desc)
        set(km.next.key, M.goto_next, km.next.desc)
        set(km.prev.key, M.goto_prev, km.prev.desc)
        set(km.parent.key, M.goto_parent, km.parent.desc)
        set(km.child.key, M.goto_child, km.child.desc)
    end
end

return M.setup() or M
