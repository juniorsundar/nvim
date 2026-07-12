local M = {}

-- Handle of the singleton scratch buffer (nil if not yet created or wiped).
local scratch_buf = nil

local RESULT_PREFIXES = {
    print = "-- >>", -- captured print() output
    value = "-- =>", -- return value of evaluated chunk
    error = "-- !!", -- runtime errors
}

--- Seed text inserted when a new scratch buffer is created.
local SEED = [[-- Neovim Lua Scratch Buffer
-- Eval visual selection: <CR> (visual mode)
-- Eval entire buffer:    <CR> (normal mode)
-- Clear results:         <localleader>x
]]

----------------------------------------------------------------------
-- Buffer lifecycle
----------------------------------------------------------------------

--- Return the existing scratch buffer if it's still valid, or nil.
local function get_existing_buf()
    if scratch_buf and vim.api.nvim_buf_is_valid(scratch_buf) then
        return scratch_buf
    end
    scratch_buf = nil
    return nil
end

--- Create a brand-new scratch buffer, seeded with SEED.
local function create_scratch_buf()
    local buf = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "lua"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].undofile = false

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(SEED, "\n"))
    scratch_buf = buf
    return buf
end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

--- Check if a line is a result line (starts with any result prefix).
---@param line string
---@return boolean
local function is_result_line(line)
    local trimmed = line:match "^%s*(.-)%s*$" or ""
    for _, prefix in pairs(RESULT_PREFIXES) do
        if vim.startswith(trimmed, prefix) then
            return true
        end
    end
    return false
end

--- Collect all non-result lines from the buffer as a single string.
---@param buf number
---@return string|nil
local function get_entire_buffer_code(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local code_lines = {}
    for _, line in ipairs(lines) do
        if not is_result_line(line) then
            table.insert(code_lines, line)
        end
    end
    if #code_lines == 0 then
        return nil
    end
    return table.concat(code_lines, "\n")
end

--- Evaluate the given Lua string and return result lines.
--- Captures print() output, return value, and pcall errors.
---@param code string
---@return string[] result_lines
local function eval_code(code)
    local result_lines = {}

    -- Redirect print() to capture its output
    local original_print = print
    local captured_output = {}
    _G.print = function(...)
        local strs = {}
        for _, v in ipairs { ... } do
            table.insert(strs, vim.inspect(v))
        end
        table.insert(captured_output, table.concat(strs, "\t"))
    end

    local ok, ret = pcall(load(code))
    _G.print = original_print

    -- Print output
    for _, line in ipairs(captured_output) do
        table.insert(result_lines, RESULT_PREFIXES.print .. " " .. line)
    end

    -- Error or return value
    if not ok then
        table.insert(result_lines, RESULT_PREFIXES.error .. " " .. tostring(ret))
    elseif ret ~= nil then
        table.insert(result_lines, RESULT_PREFIXES.value .. " " .. vim.inspect(ret))
    end

    return result_lines
end

----------------------------------------------------------------------
-- Evaluation and clearing
----------------------------------------------------------------------

--- Evaluate the entire scratch buffer and append results at the bottom.
---@param buf number
local function eval_buffer(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local code = get_entire_buffer_code(buf)
    if not code then
        return
    end

    local result_lines = eval_code(code)
    if #result_lines == 0 then
        return
    end

    local bottom = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_set_lines(buf, bottom, bottom, false, result_lines)

    -- Scroll to show results
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
        vim.api.nvim_win_call(win, function()
            vim.cmd "normal! G"
        end)
    end
end

--- Evaluate the visual selection and insert results below.
---@param buf number
local function eval_selection(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local start_line = vim.fn.line "'<"
    local end_line = vim.fn.line "'>"

    local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
    local code = table.concat(lines, "\n")

    if code:match "^%s*$" then
        return
    end

    local result_lines = eval_code(code)
    if #result_lines == 0 then
        return
    end

    -- Insert results below the selection
    vim.api.nvim_buf_set_lines(buf, end_line, end_line, false, result_lines)

    -- Exit visual mode after insertion
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

--- Remove all result lines from the scratch buffer.
---@param buf number
local function clear_results(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local keep_lines = {}
    for _, line in ipairs(lines) do
        if not is_result_line(line) then
            table.insert(keep_lines, line)
        end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, keep_lines)
end

----------------------------------------------------------------------
-- Keybindings
----------------------------------------------------------------------

--- Apply buffer-local keymaps to the scratch buffer.
local function apply_keymaps(buf)
    vim.keymap.set("n", "<CR>", function()
        eval_buffer(buf)
    end, { buffer = buf, silent = true, desc = "Eval scratch buffer" })
    vim.keymap.set("v", "<CR>", function()
        eval_selection(buf)
    end, { buffer = buf, silent = true, desc = "Eval scratch selection" })
    vim.keymap.set("n", "<localleader>x", function()
        clear_results(buf)
    end, { buffer = buf, silent = true, desc = "Clear scratch results" })
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

--- Open or focus the singleton scratch buffer.
local function open_scratch()
    local buf = get_existing_buf()

    if not buf then
        buf = create_scratch_buf()
        apply_keymaps(buf)
    end

    local existing_win = vim.fn.bufwinid(buf)
    if existing_win ~= -1 then
        vim.api.nvim_set_current_win(existing_win)
    else
        vim.api.nvim_set_current_buf(buf)
    end
end

function M.setup(_)
    -- No configurable options for now; setup is a no-op.
    -- The module is always ready; the scratch buffer is created on first open.
end

M.subcommands = {
    scratch = open_scratch,
}

return M
