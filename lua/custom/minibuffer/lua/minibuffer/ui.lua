local api = vim.api
local highlight = require "minibuffer.highlight"

local M = {}
---@class MinibufferUI
local UI = {}
UI.__index = UI

---@return MinibufferUI
function M.new(prompt_text, opts)
    local self = setmetatable({}, UI)
    self.base_prompt = prompt_text
    self.opts = opts or {}
    self.ns_id = api.nvim_create_namespace "minibuffer"
    self.prompt_ns = api.nvim_create_namespace "minibuffer_prompt"
    return self
end

function UI:get_height(count)
    local percent = self.opts.percent or 0.4
    local max_height = math.floor(vim.o.lines * percent)
    local height = math.min(max_height, count)
    return math.max(1, height)
end

function UI:create_windows()
    self.input_buf = api.nvim_create_buf(false, true)
    self.results_buf = api.nvim_create_buf(false, true)

    vim.bo[self.input_buf].filetype = "minibuffer_input"
    vim.bo[self.results_buf].filetype = "minibuffer_results"

    vim.cmd("botright " .. self:get_height(0) .. "split")
    self.results_win = api.nvim_get_current_win()
    api.nvim_win_set_buf(self.results_win, self.results_buf)

    self:_configure_window(self.results_win)

    vim.cmd "leftabove 1split"
    self.input_win = api.nvim_get_current_win()
    api.nvim_win_set_buf(self.input_win, self.input_buf)

    self:_configure_window(self.input_win)
    vim.wo[self.input_win].winfixheight = true
    vim.cmd "resize 1"

    self:update_prompt_virtual_text(self.base_prompt)

    return self.input_buf, self.input_win
end

function UI:_configure_window(win_id)
    vim.wo[win_id].number = false
    vim.wo[win_id].relativenumber = false
    vim.wo[win_id].signcolumn = "yes"
    vim.wo[win_id].cursorline = false
    vim.wo[win_id].foldcolumn = "0"
    vim.wo[win_id].spell = false
    vim.wo[win_id].list = false
end

-- Helper to update the virtual text prompt safely
function UI:update_prompt_virtual_text(text)
    if self.input_buf and api.nvim_buf_is_valid(self.input_buf) then
        api.nvim_buf_clear_namespace(self.input_buf, self.prompt_ns, 0, -1)
        api.nvim_buf_set_extmark(self.input_buf, self.prompt_ns, 0, 0, {
            virt_text = { { text, "Title" } },
            virt_text_pos = "inline",
            right_gravity = false,
        })
    end
end

---@param matches table
---@param selected_index number
---@param marked table|nil
function UI:render(matches, selected_index, marked)
    local total = #matches
    local current = selected_index

    local win_height = self:get_height(total)

    if self.results_win and api.nvim_win_is_valid(self.results_win) then
        api.nvim_win_set_height(self.results_win, win_height)
        if self.input_win and api.nvim_win_is_valid(self.input_win) then
            api.nvim_win_set_height(self.input_win, 1)
        end
    end

    local count_str = ""
    if total > 0 then
        count_str = string.format("%d/%d ", current, total)
    else
        count_str = "0/0 "
    end

    self:update_prompt_virtual_text(count_str .. self.base_prompt)

    if total == 0 then
        api.nvim_buf_set_lines(self.results_buf, 0, -1, false, { " " })
        return
    end

    local start_idx = 1
    local end_idx = total

    if total > win_height then
        local half_height = math.floor(win_height / 2)
        start_idx = math.max(1, selected_index - half_height)
        end_idx = math.min(total, start_idx + win_height - 1)

        if end_idx - start_idx + 1 < win_height then
            start_idx = math.max(1, end_idx - win_height + 1)
        end
    end

    local visible_matches = {}
    for i = start_idx, end_idx do
        table.insert(visible_matches, matches[i])
    end

    api.nvim_buf_set_lines(self.results_buf, 0, -1, false, visible_matches)
    api.nvim_buf_clear_namespace(self.results_buf, self.ns_id, 0, -1)

    for i, line in ipairs(visible_matches) do
        local line_idx = i - 1
        highlight.highlight_entry(self.results_buf, self.ns_id, line_idx, line, true)

        if marked and marked[line] then
            api.nvim_buf_set_extmark(self.results_buf, self.ns_id, line_idx, 0, {
                sign_text = "●",
                sign_hl_group = "String",
                priority = 105,
            })
        end
    end

    local relative_selected_idx = selected_index - start_idx + 1
    if relative_selected_idx > 0 and relative_selected_idx <= #visible_matches then
        local selected_text = visible_matches[relative_selected_idx]

        api.nvim_buf_set_extmark(self.results_buf, self.ns_id, relative_selected_idx - 1, 0, {
            end_row = relative_selected_idx - 1,
            end_col = #selected_text,
            hl_group = "Visual",
            priority = 100,
        })
        pcall(api.nvim_win_set_cursor, self.results_win, { relative_selected_idx, 0 })
    end
end

function UI:set_prompt(text)
    self.base_prompt = text
    self:update_prompt_virtual_text(text)
end

function UI:update_input(lines)
    api.nvim_buf_set_lines(self.input_buf, 0, -1, false, lines)
    api.nvim_win_set_cursor(self.input_win, { 1, #lines[1] })
end

function UI:close()
    if self.results_win and api.nvim_win_is_valid(self.results_win) then
        pcall(api.nvim_win_close, self.results_win, true)
    end
    if self.input_win and api.nvim_win_is_valid(self.input_win) then
        pcall(api.nvim_win_close, self.input_win, true)
    end

    if self.results_buf and api.nvim_buf_is_valid(self.results_buf) then
        api.nvim_buf_delete(self.results_buf, { force = true })
    end
    if self.input_buf and api.nvim_buf_is_valid(self.input_buf) then
        api.nvim_buf_delete(self.input_buf, { force = true })
    end
    vim.cmd "stopinsert"
end

return M
