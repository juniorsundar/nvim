vim.opt.statusline = " "
vim.api.nvim_set_hl(0, "StatusLine", { bg = "None", fg = "None" })
vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "None", fg = "None" })

local IGNORED_NAMES = {
    ["[LSP Eldoc]"] = true,
    ["NvimTree_1"] = true,
    ["No Name"] = true,
}

local IGNORED_BUFTYPES = {
    ["nofile"] = true,
    ["nowrite"] = true,
    ["prompt"] = true,
    ["popup"] = true,
    ["terminal"] = true,
}

local IGNORED_FILETYPES = {
    ["fugitive"] = true,
    ["oil"] = true,
}

-- Helper function to check if a buffer should be ignored
local function is_ignored(buf_id, win_id)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf_id), ":t")
    local buftype = vim.bo[buf_id].buftype
    local filetype = vim.bo[buf_id].filetype

    if IGNORED_NAMES[name] then return true end
    if IGNORED_BUFTYPES[buftype] then return true end
    if IGNORED_FILETYPES[filetype] then return true end
    return false
end

local window_status_map = {}
local palette = require("theme.colors").dark
local colors = {
    bg = palette.bg_alt,
    fg = palette.fg,
    yellow = palette.yellow,
    cyan = palette.cyan,
    darkblue = palette.dark_blue,
    green = palette.green,
    orange = palette.orange,
    violet = palette.violet,
    magenta = palette.magenta,
    blue = palette.blue,
    red = palette.red,
}

local mode_colors = {
    n = colors.blue,
    i = colors.green,
    v = colors.red,
    [""] = colors.red,
    V = colors.red,
    c = colors.magenta,
    no = colors.red,
    s = colors.orange,
    S = colors.orange,
    [''] = colors.orange,
    ic = colors.yellow,
    R = colors.violet,
    Rv = colors.violet,
    cv = colors.red,
    ce = colors.red,
    r = colors.cyan,
    rm = colors.cyan,
    ["r?"] = colors.cyan,
    ["!"] = colors.red,
    t = colors.red,
}
local function get_mode_color()
    return mode_colors[vim.fn.mode()] or colors.blue
end

local function get_git_branch(buf_id)
    local icon = " "
    local signs = vim.b[buf_id].gitsigns_status_dict
    if signs then
        return icon .. (signs.head or "")
    end
    return ""
end

local function get_diagnostics(buf_id)
    local count = vim.diagnostic.count(buf_id)
    local errors = count[vim.diagnostic.severity.ERROR] or 0
    local warnings = count[vim.diagnostic.severity.WARN] or 0
    local hints = count[vim.diagnostic.severity.HINT] or 0

    local parts = {}
    if hints > 0 then table.insert(parts, " " .. hints) end
    if errors > 0 then table.insert(parts, " " .. errors) end
    if warnings > 0 then table.insert(parts, " " .. warnings) end

    if #parts > 0 then
        return table.concat(parts, " ")
    end
    return ""
end

local function get_file_info(buf_id)
    local full_path = vim.api.nvim_buf_get_name(buf_id)

    local filename = vim.fn.fnamemodify(full_path, ":.")
    if filename == "" then filename = "[No Name]" end

    local extension = vim.fn.fnamemodify(full_path, ":e")
    local filename_tail = vim.fn.fnamemodify(full_path, ":t")

    local icon, icon_color = require("nvim-web-devicons").get_icon(filename_tail, extension, { default = true })

    return icon, filename, icon_color
end

local function update_split_status()
    -- Cleanup closed windows
    for parent_win_id, status_win_id in pairs(window_status_map) do
        if not vim.api.nvim_win_is_valid(parent_win_id) then
            if vim.api.nvim_win_is_valid(status_win_id) then
                vim.api.nvim_win_close(status_win_id, true)
            end
            window_status_map[parent_win_id] = nil
        end
    end

    local visible_wins = vim.api.nvim_tabpage_list_wins(0)

    for _, win_id in ipairs(visible_wins) do
        if vim.api.nvim_win_is_valid(win_id) then
            local config_custom = vim.api.nvim_win_get_config(win_id)

            if config_custom.relative == "" then
                local buf_id = vim.api.nvim_win_get_buf(win_id)

                if is_ignored(buf_id, win_id) then
                    local existing_status = window_status_map[win_id]
                    if existing_status and vim.api.nvim_win_is_valid(existing_status) then
                        vim.api.nvim_win_close(existing_status, true)
                        window_status_map[win_id] = nil
                    end
                else
                    local is_active = (vim.api.nvim_get_current_win() == win_id)
                    local width = vim.api.nvim_win_get_width(win_id)

                    -- Data Gathering
                    local icon, filename, _ = get_file_info(buf_id)
                    local branch = get_git_branch(buf_id)
                    local diagnostics = get_diagnostics(buf_id)
                    local mode_hl_color = get_mode_color()

                    local left_text = string.format(" %s  %s", icon, filename)
                    local right_text = string.format("%s  %s ", diagnostics, branch)

                    local available_space = width - vim.fn.strdisplaywidth(left_text) -
                        vim.fn.strdisplaywidth(right_text)
                    if available_space < 0 then available_space = 1 end

                    local content = left_text .. string.rep(" ", available_space) .. right_text

                    local height = vim.api.nvim_win_get_height(win_id)
                    if not is_active then
                        height = height - 1
                    end
                    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf_id), ":t")

                    if name == "" then name = "[No Name]" end

                    local status_win = window_status_map[win_id]
                    local status_buf = nil
                    local top_border = { " ", "_", "", "", "", "", "", "" }

                    if status_win and vim.api.nvim_win_is_valid(status_win) then
                        status_buf = vim.api.nvim_win_get_buf(status_win)
                        vim.api.nvim_win_set_config(status_win, {
                            relative = "win",
                            win = win_id,
                            width = width,
                            height = 1,
                            row = height,
                            col = 0,
                            border = top_border
                        })
                    else
                        status_buf = vim.api.nvim_create_buf(false, true)
                        status_win = vim.api.nvim_open_win(status_buf, false, {
                            relative = "win",
                            win = win_id,
                            width = width,
                            height = 1,
                            row = height,
                            col = 0,
                            style = "minimal",
                            border = top_border,
                            focusable = false,
                            zindex = 10,
                        })
                        window_status_map[win_id] = status_win
                    end

                    vim.api.nvim_buf_set_lines(status_buf, 0, -1, false, { content })

                    local border_color_group = "FloatBorder"

                    if is_active then
                        local mode = vim.api.nvim_get_mode()["mode"]
                        if mode == "\22" then mode = "VBlock" end
                        if mode == "\19" then mode = "SBlock" end
                        local hl_name = "StatusBorderActive" .. mode
                        vim.api.nvim_set_hl(0, hl_name, { fg = mode_hl_color })
                        border_color_group = hl_name
                    else
                        border_color_group = "Comment"
                    end

                    vim.api.nvim_set_option_value("winhighlight", "Normal:Normal,FloatBorder:" .. border_color_group,
                        { win = status_win })
                end
            end
        end
    end
end

local gid = vim.api.nvim_create_augroup("SplitStatus", { clear = true })
vim.api.nvim_create_autocmd(
    { "WinEnter", "WinClosed", "VimResized", "BufEnter", "CursorHold", "ModeChanged" },
    {
        group = gid,
        callback = update_split_status,
    })

local scroll_gid = vim.api.nvim_create_augroup("AutoScrollBottom", { clear = true })
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = scroll_gid,
    callback = function()
        local win_id = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_config(win_id).relative ~= "" then return end

        local current_line = vim.fn.line('.')
        local last_line = vim.fn.line('$')


        if current_line == last_line then
            local win_height = vim.api.nvim_win_get_height(win_id)
            local cursor_win_line = vim.fn.winline()

            if math.abs(cursor_win_line - win_height) <= 1 then
                vim.cmd("normal! \5")
            end
        else
            return
        end
    end,
})
