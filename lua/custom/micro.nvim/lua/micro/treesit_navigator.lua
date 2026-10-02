local panel = require "micro.panel"

---@class TreesitNavigatorConfig
---@field highlights { source_node: string, tree_node: string, tree_win_hl: string }
---@field icons { branch_mid: string, branch_end: string, indent_mid: string, indent_end: string }
---@field window { border: string, width_padding: number }
---@field keymaps { enable: boolean, prefix: string, toggle: string, next: string, prev: string, parent: string, child: string, node_start: string, node_end: string }

---@class TreesitNavigator
local M = {}

---@type TreesitNavigatorConfig
local defaults = {
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
}
local config = defaults

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

local TRANSIENT = { "parent", "child", "next", "prev", "node_start", "node_end" }

local function clear_transient_keymaps()
    if state.source_buf and vim.api.nvim_buf_is_valid(state.source_buf) then
        for _, name in ipairs(TRANSIENT) do
            local key = config.keymaps[name]
            if key then
                for _, mode in ipairs { "n", "v" } do
                    pcall(vim.keymap.del, mode, key, { buffer = state.source_buf })
                end
            end
        end
    end
end

local function set_transient_keymaps()
    if state.source_buf and vim.api.nvim_buf_is_valid(state.source_buf) then
        local opts = { buffer = state.source_buf, nowait = true, silent = true }
        local function set(name, func)
            local key = config.keymaps[name]
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
    panel.close "ts_tree"
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
        local child = (node:type() == "block" or node:type() == "statement_block") and node:named_child(0)
        if not child then
            break
        end
        node = child
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
        -- A zero end column means the node ends on the previous line.
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
            hl_group = config.highlights.source_node,
            priority = 100,
        })
    end
end

M.ts_tree_display = function()
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
    local conf = config

    table.insert(lines, root_of_view:type())
    if not parent then
        table.insert(highlights, { #lines - 1, conf.highlights.tree_node })
    end

    local children = root_of_view:named_children()

    for i, child in ipairs(children) do
        local is_last = (i == #children)
        local marker = is_last and conf.icons.branch_end or conf.icons.branch_mid
        local is_target = (child:id() == node:id())

        table.insert(lines, marker .. child:type())

        if is_target then
            table.insert(highlights, { #lines - 1, conf.highlights.tree_node })

            local indent = is_last and conf.icons.indent_end or conf.icons.indent_mid
            local grandchildren = child:named_children()
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

    local fresh = not panel.get "ts_tree"
    local buf
    state.tree_win, buf = panel.open("ts_tree", lines, opts)
    if fresh then
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

M.goto_node_start = function()
    local node = get_nav_node()
    if node then
        update_nav(node, "start")
    end
end

M.goto_node_end = function()
    local node = get_nav_node()
    if node then
        update_nav(node, "end")
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
            update_nav(parent, "start")
            return
        end
        parent = parent:parent()
    end
end

local function find_first_child_jump(node, root_start_row, root_start_col)
    for _, child in ipairs(node:named_children()) do
        local r, c = child:start()
        if r ~= root_start_row or c ~= root_start_col then
            return child
        end
        local found = find_first_child_jump(child, root_start_row, root_start_col)
        if found then
            return found
        end
    end
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
        update_nav(target, "start")
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
        update_nav(next, "start")
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
        update_nav(prev, "start")
    end
end

---Setup function to initialize the plugin with user options.
---@param opts? table Partial configuration to merge with defaults.
M.setup = function(opts)
    config = vim.tbl_deep_extend("force", defaults, opts or {})

    if config.keymaps.enable then
        local km = config.keymaps
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

return M
