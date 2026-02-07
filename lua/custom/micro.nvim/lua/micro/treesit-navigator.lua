---@class TreesitNavigatorConfig
---@field highlights { source_node: string, tree_node: string, tree_win_hl: string }
---@field icons { branch_mid: string, branch_end: string, indent_mid: string, indent_end: string }
---@field window { border: string, width_padding: number }
---@field keymaps { enable: boolean, prefix: string, toggle: string, next: string, prev: string, parent: string, child: string, node_start: string, node_end: string }
---@field transient_keymaps { enable: boolean }

---@class TreesitNavigator
local M = {}

---Default configuration
---@type TreesitNavigatorConfig
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
        prefix = "<leader>T",
        toggle = "t",
        next = "l",
        prev = "h",
        parent = "k",
        child = "j",
        node_start = "0",
        node_end = "$",
    },
    transient_keymaps = {
        enable = true,
    },
}

---@class TreesitNavigatorState
---@field tree_win? integer Window ID of the tree view
---@field sticky_node? TSNode The node currently stuck to (navigating relative to)
---@field sticky_pos_type "start"|"end" Where the cursor is stuck relative to the node
---@field is_navigating boolean Flag to prevent recursive updates
---@field source_buf? integer Buffer ID of the source code
---@field ns_nav integer Namespace ID for highlighting
---@field tree_grp integer Autocommand group ID
local state = {
    tree_win = nil,
    sticky_node = nil,
    sticky_pos_type = "start",
    is_navigating = false,
    source_buf = nil,
    ns_nav = vim.api.nvim_create_namespace "ts_nav",
    tree_grp = vim.api.nvim_create_augroup("TSTreeDisplay", { clear = true }),
}

local function clear_highlights()
    if state.source_buf and vim.api.nvim_buf_is_valid(state.source_buf) then
        vim.api.nvim_buf_clear_namespace(state.source_buf, state.ns_nav, 0, -1)
    end
end

local function get_transient_key(name)
    return M.config.transient_keymaps[name] or M.config.keymaps[name]
end

local function clear_transient_keymaps()
    if not M.config.transient_keymaps.enable then
        return
    end
    if state.source_buf and vim.api.nvim_buf_is_valid(state.source_buf) then
        local keys = {
            get_transient_key "parent",
            get_transient_key "child",
            get_transient_key "next",
            get_transient_key "prev",
            get_transient_key "node_start",
            get_transient_key "node_end",
        }
        for _, key in ipairs(keys) do
            if key then
                for _, mode in ipairs { "n", "v" } do
                    pcall(vim.keymap.del, mode, key, { buffer = state.source_buf })
                end
            end
        end
    end
end

local function set_transient_keymaps()
    if not M.config.transient_keymaps.enable then
        return
    end
    if state.source_buf and vim.api.nvim_buf_is_valid(state.source_buf) then
        local opts = { buffer = state.source_buf, nowait = true, silent = true }
        local function set(name, func)
            local key = get_transient_key(name)
            if type(key) == "string" then
                vim.keymap.set({ "n", "v" }, key, func, opts)
            end
        end

        set("parent", M.goto_parent)
        set("child", M.goto_child)
        set("next", M.goto_next)
        set("prev", M.goto_prev)
        set("node_start", M.goto_node_start)
        set("node_end", M.goto_node_end)
    end
end

local function close_tree_win()
    if state.tree_win and vim.api.nvim_win_is_valid(state.tree_win) then
        vim.api.nvim_win_close(state.tree_win, true)
    end
    state.tree_win = nil
    clear_highlights()
    clear_transient_keymaps()
    state.source_buf = nil
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
                if child and child:named() then
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

local function get_node_end_pos(node, buf)
    local _, _, er, ec = node:range()
    if ec == 0 then
        -- Ends at start of line, so actually ends at previous line
        if er > 0 then
            local r = er - 1
            if buf and vim.api.nvim_buf_is_valid(buf) then
                local line = vim.api.nvim_buf_get_lines(buf, r, r + 1, false)[1] or ""
                local c = math.max(0, #line - 1)
                return r, c
            else
                return r, 0
            end
        else
            return 0, 0
        end
    else
        return er, ec - 1
    end
end

local function get_sticky_node()
    if not state.sticky_node then
        return nil
    end
    local ok, sr, sc = pcall(function()
        return state.sticky_node:range()
    end)
    if not ok then
        state.sticky_node = nil
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local cr, cc = cursor[1] - 1, cursor[2]

    local tr, tc
    if state.sticky_pos_type == "end" then
        tr, tc = get_node_end_pos(state.sticky_node, state.source_buf)
    else
        tr, tc = sr, sc
    end

    if tr ~= cr or tc ~= cc then
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
    if target_node and state.source_buf and vim.api.nvim_buf_is_valid(state.source_buf) then
        local start_row, start_col, end_row, end_col = target_node:range()
        vim.api.nvim_buf_set_extmark(state.source_buf, state.ns_nav, start_row, start_col, {
            end_row = end_row,
            end_col = end_col,
            hl_group = M.config.highlights.source_node,
            priority = 100,
        })
    end
end

---Displays the treesitter tree view for the current node.
M.ts_tree_display = function()
    -- Initialize source buffer if starting fresh
    if not state.tree_win then
        state.source_buf = vim.api.nvim_get_current_buf()
    end

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
        if child and child:named() then
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
                if grandchild and grandchild:named() then
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

        set_transient_keymaps()

        vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave", "BufWipeout" }, {
            group = state.tree_grp,
            buffer = state.source_buf,
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

local function update_nav(target_node, pos_type)
    if target_node then
        local r, c
        if pos_type == "end" then
            r, c = get_node_end_pos(target_node, state.source_buf)
        else
            r, c = target_node:start()
        end

        state.is_navigating = true
        state.sticky_pos_type = pos_type or "start"
        vim.api.nvim_win_set_cursor(0, { r + 1, c })
        state.sticky_node = target_node
        highlight_source_node(target_node)
        M.ts_tree_display()
        state.is_navigating = false
    end
end

---Moves the cursor to the start of the current navigation node.
M.goto_node_start = function()
    local node = get_nav_node()
    if node then
        update_nav(node, "start")
    end
end

---Moves the cursor to the end of the current navigation node.
M.goto_node_end = function()
    local node = get_nav_node()
    if node then
        update_nav(node, "end")
    end
end

---Moves the cursor to the parent of the current navigation node.
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
            update_nav(parent, "start")
            return
        end
        parent = parent:parent()
    end
end

local function find_first_child_jump(node, root_start_row, root_start_col)
    local count = node:child_count()
    for i = 0, count - 1 do
        local child = node:child(i)
        if child and child:named() then
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

---Moves the cursor to the first child of the current navigation node.
M.goto_child = function()
    local node = get_nav_node()
    if not node then
        return
    end

    local n_row, n_col = node:start()
    local target = find_first_child_jump(node, n_row, n_col)

    if target then
        target = dive_into_block(target)
        update_nav(target, "start")
    end
end

---Moves the cursor to the next named sibling of the current navigation node.
M.goto_next = function()
    local node = get_nav_node()
    if not node then
        return
    end

    local next = node:next_named_sibling()
    if next then
        next = dive_into_block(next)
        update_nav(next, "start")
    end
end

---Moves the cursor to the previous named sibling of the current navigation node.
M.goto_prev = function()
    local node = get_nav_node()
    if not node then
        return
    end

    local prev = node:prev_named_sibling()
    if prev then
        prev = dive_into_block(prev)
        update_nav(prev, "start")
    end
end

---Setup function to initialize the plugin with user options.
---@param opts? table Partial configuration to merge with defaults.
M.setup = function(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    if M.config.keymaps.enable then
        local km = M.config.keymaps
        local prefix = km.prefix or ""

        if prefix ~= "" then
            vim.keymap.set({ "n", "v" }, prefix, "<nop>", { desc = "Treesit Navigator" })
        end

        local set = function(key, func, desc)
            if key then
                vim.keymap.set({ "n", "v" }, prefix .. key, func, { desc = desc })
            end
        end

        set(km.toggle, M.ts_tree_display, "show treesitter context")
        set(km.next, M.goto_next, "next treesitter sibling")
        set(km.prev, M.goto_prev, "prev treesitter sibling")
        set(km.parent, M.goto_parent, "parent treesitter node")
        set(km.child, M.goto_child, "child treesitter node")
        set(km.node_start, M.goto_node_start, "start of treesitter node")
        set(km.node_end, M.goto_node_end, "end of treesitter node")
    end
end

return M.setup() or M
