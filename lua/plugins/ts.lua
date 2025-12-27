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

local get_master_node = function()
    local node = vim.treesitter.get_node()
    return dive_into_block(node)
end

local sticky_node = nil

local function get_sticky_node()
    if not sticky_node then
        return nil
    end
    local ok, sr, sc = pcall(function()
        return sticky_node:start()
    end)
    if not ok then
        sticky_node = nil
        return nil
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cr, cc = cursor[1] - 1, cursor[2]
    if sr ~= cr or sc ~= cc then
        sticky_node = nil
        return nil
    end
    return sticky_node
end

local function get_nav_node()
    return get_sticky_node() or get_master_node()
end

local tree_win = nil
local is_navigating = false
local tree_grp = vim.api.nvim_create_augroup("TSTreeDisplay", { clear = true })

local function close_tree_win()
    if tree_win and vim.api.nvim_win_is_valid(tree_win) then
        vim.api.nvim_win_close(tree_win, true)
    end
    tree_win = nil
    vim.api.nvim_clear_autocmds { group = tree_grp }
end

local ts_tree_display = function()
    local node = get_nav_node()

    if not node then
        if not is_navigating then
            print "no treesitter node found"
        end
        if tree_win and not is_navigating then
            close_tree_win()
        end
        return
    end

    local parent = node:parent()
    local root_of_view = parent or node

    local lines = {}
    local root_suffix = (not parent) and " <--" or ""
    table.insert(lines, root_of_view:type() .. root_suffix)

    local children = {}
    for i = 0, root_of_view:child_count() - 1 do
        local child = root_of_view:child(i)
        if child:named() then
            table.insert(children, child)
        end
    end

    for i, child in ipairs(children) do
        local is_last = (i == #children)
        local marker = is_last and "└── " or "├── "
        local is_target = (child:id() == node:id())
        local suffix = is_target and " <--" or ""
        table.insert(lines, marker .. child:type() .. suffix)

        if is_target then
            local indent = is_last and "    " or "│   "
            local grandchildren = {}
            for j = 0, child:child_count() - 1 do
                local grandchild = child:child(j)
                if grandchild:named() then
                    table.insert(grandchildren, grandchild)
                end
            end
            for j, grandchild in ipairs(grandchildren) do
                local g_is_last = (j == #grandchildren)
                local g_marker = g_is_last and "└── " or "├── "
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
        width = width + 2,
        height = #lines,
        col = vim.api.nvim_win_get_width(0),
        row = 0,
        style = "minimal",
        border = "solid",
    }

    if tree_win and vim.api.nvim_win_is_valid(tree_win) then
        local buf = vim.api.nvim_win_get_buf(tree_win)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_win_set_config(tree_win, opts)
    else
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].bufhidden = "wipe"

        tree_win = vim.api.nvim_open_win(buf, false, opts)

        vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
            group = tree_grp,
            buffer = 0,
            callback = function(ev)
                if is_navigating then
                    return
                end
                if ev.event == "CursorMoved" and get_sticky_node() then
                    return
                end
                close_tree_win()
            end,
        })
    end
end

local function update_nav(target_node)
    if target_node then
        local r, c = target_node:start()
        is_navigating = true
        vim.api.nvim_win_set_cursor(0, { r + 1, c })
        sticky_node = target_node
        if tree_win and vim.api.nvim_win_is_valid(tree_win) then
            ts_tree_display()
        end
        is_navigating = false
    end
end

local goto_parent = function()
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
                -- Child is at same position, try to drill down
                local found = find_first_child_jump(child, root_start_row, root_start_col)
                if found then
                    return found
                end
            end
        end
    end
    return nil
end

local goto_child = function()
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

local goto_next = function()
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

local goto_prev = function()
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

vim.keymap.set({ "v", "n" }, "<leader>Tt", ts_tree_display, { desc = "show treesitter context" })
vim.keymap.set({ "v", "n" }, "<leader>T]", goto_next, { desc = "next treesitter sibling" })
vim.keymap.set({ "v", "n" }, "<leader>T[", goto_prev, { desc = "prev treesitter sibling" })
vim.keymap.set({ "v", "n" }, "<leader>Tk", goto_parent, { desc = "parent treesitter node" })
vim.keymap.set({ "v", "n" }, "<leader>Tj", goto_child, { desc = "child treesitter node" })
