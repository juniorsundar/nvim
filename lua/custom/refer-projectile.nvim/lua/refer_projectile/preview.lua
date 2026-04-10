local M = {}

local _buf = nil
local _win = nil
local _tabpage = nil

--- Open a new full-screen preview tab and return its tabpage and window handles.
--- If a preview tab already exists and is valid, returns it without creating a new one.
--- @return number, number tabpage handle, window handle
function M.open_preview_tab()
    -- Reuse existing valid tab
    if _tabpage ~= nil and vim.api.nvim_tabpage_is_valid(_tabpage) then
        local win = _win
        if win ~= nil and vim.api.nvim_win_is_valid(win) then
            return _tabpage, win
        end
    end

    -- Close any orphaned state
    M.close_tab()

    -- Create new tab
    vim.cmd "tabnew"

    -- The new tab is always the last one in the list
    local all_tabs = vim.api.nvim_list_tabpages()
    local tabpage = all_tabs[#all_tabs]

    -- Get the only window in this new tab
    local win = vim.api.nvim_tabpage_list_wins(tabpage)[1]

    -- Maximize to fill the tab (accounts for tabline + statusline heights)
    vim.api.nvim_win_set_width(win, vim.o.columns)
    vim.api.nvim_win_set_height(win, vim.o.lines)

    -- Exit insert mode if accidentally entered (tabnew can trigger it)
    vim.cmd "stopinsert"

    _tabpage = tabpage
    _win = win

    return tabpage, win
end

--- Render ANSI output into the preview tab window.
--- If the output has more lines than the window height, truncates from both
--- top and bottom with a separator line in the middle.
--- @param tabpage number Tabpage handle
--- @param win number Window handle
--- @param output string Raw ANSI text from tmux capture-pane -p -e
function M.render_tab(tabpage, win, output)
    -- Guard: tab/window may have been closed by the time the async callback fires
    if not vim.api.nvim_tabpage_is_valid(tabpage) or not vim.api.nvim_win_is_valid(win) then
        return
    end

    local prev_buf = _buf
    local win_height = vim.api.nvim_win_get_height(win)

    -- Always strip first and last 5 lines from the tmux pane capture.
    -- tmux pane borders and status lines are uninteresting; the content
    -- is what matters for the preview.
    local lines = vim.split(output, "\n", { plain = true })
    local original_count = #lines
    local border_count = math.min(5, math.floor(original_count / 2))
    lines = { unpack(lines, border_count + 1, original_count - border_count) }
    local hidden_count = original_count - #lines

    -- If still too tall for the window, truncate from top and bottom with a separator
    if #lines > win_height then
        local keep = math.floor(win_height / 2) - 1
        local separator = ("~ %d lines hidden ~"):format(hidden_count)
        local top = { unpack(lines, 1, keep) }
        local bottom = { unpack(lines, #lines - keep + 1, #lines) }
        lines = vim.list_extend(vim.list_extend(top, { separator }), bottom)
    end

    -- Create and populate the new buffer
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "filetype", "raw")

    -- Place the new buffer in the window first, then delete the old one
    vim.api.nvim_win_set_buf(win, bufnr)

    if prev_buf ~= nil and vim.api.nvim_buf_is_valid(prev_buf) then
        vim.api.nvim_buf_delete(prev_buf, { force = true })
    end

    -- nvim_open_term reads buffer contents and renders ANSI codes as colours
    vim.api.nvim_open_term(bufnr, {})

    _buf = bufnr
    _win = win
    _tabpage = tabpage
end

--- Close the preview tab if open.
function M.close_tab()
    if _tabpage ~= nil and vim.api.nvim_tabpage_is_valid(_tabpage) then
        pcall(vim.api.nvim_tabpage_close, _tabpage, true)
    end
    M.cleanup()
end

--- Clean up the preview buffer (call on picker close).
function M.cleanup()
    _tabpage = nil
    _win = nil
    local buf = _buf
    _buf = nil
    if buf ~= nil and vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end
end

return M
