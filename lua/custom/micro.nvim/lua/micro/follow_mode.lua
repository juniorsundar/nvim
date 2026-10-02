local M = {}

local state = {}

local function is_line_visible_in_window(win, line)
    local win_info = vim.fn.getwininfo(win)[1]
    if not win_info then
        return false
    end
    return line >= win_info.topline and line <= win_info.botline
end

local function maybe_switch_to_partner(buf)
    local s = state[buf]
    if not s then
        return
    end

    local current_win = vim.api.nvim_get_current_win()
    local cursor_line = vim.api.nvim_win_get_cursor(current_win)[1]

    if is_line_visible_in_window(current_win, cursor_line) then
        return
    end

    local partner = s.win1 == current_win and s.win2 or s.win1

    if not vim.api.nvim_win_is_valid(partner) then
        return
    end

    if is_line_visible_in_window(partner, cursor_line) then
        vim.api.nvim_set_current_win(partner)
        vim.api.nvim_win_set_cursor(partner, { cursor_line, 0 })
    end
end

local function update_cursor_visibility(buf)
    local s = state[buf]
    if not s then
        return
    end

    local current_win = vim.api.nvim_get_current_win()

    if current_win == s.win1 then
        if vim.api.nvim_win_is_valid(s.win1) then
            vim.api.nvim_set_option_value("cursorline", true, { win = s.win1 })
        end
        if vim.api.nvim_win_is_valid(s.win2) then
            vim.api.nvim_set_option_value("cursorline", false, { win = s.win2 })
        end
    else
        if vim.api.nvim_win_is_valid(s.win2) then
            vim.api.nvim_set_option_value("cursorline", true, { win = s.win2 })
        end
        if vim.api.nvim_win_is_valid(s.win1) then
            vim.api.nvim_set_option_value("cursorline", false, { win = s.win1 })
        end
    end
end

local function is_window_before(win_a, win_b)
    local pos_a = vim.fn.win_screenpos(win_a)
    local pos_b = vim.fn.win_screenpos(win_b)
    if pos_a[2] ~= pos_b[2] then
        return pos_a[2] < pos_b[2]
    end
    return pos_a[1] < pos_b[1]
end

local function realign_partner(active_win)
    local buf = vim.api.nvim_win_get_buf(active_win)
    local s = state[buf]

    if not s then
        return
    end

    local partner = s.win1 == active_win and s.win2 or s.win1

    if not vim.api.nvim_win_is_valid(partner) then
        return
    end

    local active_info = vim.fn.getwininfo(active_win)[1]
    if not active_info then
        return
    end

    local partner_topline

    if is_window_before(active_win, partner) then
        partner_topline = active_info.botline + 1
    else
        local partner_info = vim.fn.getwininfo(partner)[1]
        if not partner_info then
            return
        end
        local partner_visible_lines = partner_info.botline - partner_info.topline + 1
        partner_topline = math.max(1, active_info.topline - partner_visible_lines)
    end

    local line_count = vim.api.nvim_buf_line_count(buf)
    if partner_topline > line_count then
        partner_topline = line_count
    end

    vim.api.nvim_win_set_cursor(partner, { partner_topline, 0 })
    vim.api.nvim_win_call(partner, function()
        vim.cmd "normal! zt"
    end)
end

local function deactivate_follow_mode(buf)
    local s = state[buf]

    if not s then
        return
    end

    if s.saved_cursorline then
        if vim.api.nvim_win_is_valid(s.win1) then
            vim.api.nvim_set_option_value("cursorline", s.saved_cursorline[s.win1], { win = s.win1 })
        end
        if vim.api.nvim_win_is_valid(s.win2) then
            vim.api.nvim_set_option_value("cursorline", s.saved_cursorline[s.win2], { win = s.win2 })
        end
    end

    if s.augroup then
        pcall(vim.api.nvim_del_augroup_by_id, s.augroup)
    end

    if s.created_by_follow_split then
        local partner = s.win1 == vim.api.nvim_get_current_win() and s.win2 or s.win1
        if vim.api.nvim_win_is_valid(partner) then
            vim.api.nvim_win_close(partner, true)
        end
    end

    state[buf] = nil
    vim.notify("Follow-mode deactivated", vim.log.levels.INFO)
end

local function activate_follow_mode(win1, win2, created_by_follow_split)
    local buf = vim.api.nvim_win_get_buf(win1)
    local buf2 = vim.api.nvim_win_get_buf(win2)

    if buf ~= buf2 then
        vim.notify("Follow-mode requires both windows to show the same buffer", vim.log.levels.ERROR)
        return false
    end

    local existing = state[buf]
    if existing then
        deactivate_follow_mode(buf)
    end

    local augroup = vim.api.nvim_create_augroup("MicroFollowMode_" .. buf, { clear = true })

    local saved_cursorline = {
        [win1] = vim.api.nvim_get_option_value("cursorline", { win = win1 }),
        [win2] = vim.api.nvim_get_option_value("cursorline", { win = win2 }),
    }

    state[buf] = {
        win1 = win1,
        win2 = win2,
        augroup = augroup,
        created_by_follow_split = created_by_follow_split,
        saved_cursorline = saved_cursorline,
    }

    vim.api.nvim_create_autocmd("WinScrolled", {
        group = augroup,
        callback = function()
            local current_win = vim.api.nvim_get_current_win()
            local current_buf = vim.api.nvim_win_get_buf(current_win)

            if current_buf == buf then
                realign_partner(current_win)
            end
        end,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
        group = augroup,
        callback = function()
            local current_buf = vim.api.nvim_get_current_buf()
            if current_buf == buf then
                maybe_switch_to_partner(buf)
            end
        end,
    })

    vim.api.nvim_create_autocmd("WinEnter", {
        group = augroup,
        callback = function()
            local current_buf = vim.api.nvim_get_current_buf()
            if current_buf == buf then
                update_cursor_visibility(buf)
            end
        end,
    })

    vim.api.nvim_create_autocmd("WinClosed", {
        group = augroup,
        callback = function()
            local s = state[buf]
            if s then
                if not vim.api.nvim_win_is_valid(s.win1) or not vim.api.nvim_win_is_valid(s.win2) then
                    deactivate_follow_mode(buf)
                end
            end
        end,
    })

    realign_partner(win1)

    update_cursor_visibility(buf)

    vim.notify("Follow-mode activated", vim.log.levels.INFO)
    return true
end

local function is_follow_mode_active(buf)
    return state[buf] ~= nil
end

local function follow_split()
    local buf = vim.api.nvim_get_current_buf()
    local current_win = vim.api.nvim_get_current_win()

    if is_follow_mode_active(buf) then
        deactivate_follow_mode(buf)
        return
    end

    vim.cmd "vsplit"

    local new_win = vim.api.nvim_get_current_win()

    vim.api.nvim_set_current_win(current_win)

    activate_follow_mode(current_win, new_win, true)
end

local function follow_mode()
    local buf = vim.api.nvim_get_current_buf()
    local current_win = vim.api.nvim_get_current_win()

    if is_follow_mode_active(buf) then
        deactivate_follow_mode(buf)
        return
    end

    local windows = vim.api.nvim_list_wins()
    local partner = nil

    for _, win in ipairs(windows) do
        if win ~= current_win and vim.api.nvim_win_get_buf(win) == buf then
            partner = win
            break
        end
    end

    if not partner then
        vim.notify(
            "No other window showing the same buffer. Use ':Micro follow split' to create one.",
            vim.log.levels.WARN
        )
        return
    end

    activate_follow_mode(current_win, partner, false)
end

M.subcommands = {
    follow = {
        split = follow_split,
        mode = follow_mode,
    },
}

return M
