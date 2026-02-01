local api = vim.api
local highlight = require "minibuffer.highlight"

local M = {}
local UI = {}
UI.__index = UI

function M.new(prompt_text)
    local self = setmetatable({}, UI)
    self.prompt_text = prompt_text
    self.ns_id = api.nvim_create_namespace "minibuffer"
    self.prompt_ns = api.nvim_create_namespace "minibuffer_prompt"
    return self
end

function UI:create_windows()
    self.input_buf = api.nvim_create_buf(false, true)
    self.results_buf = api.nvim_create_buf(false, true)

    vim.bo[self.input_buf].filetype = "minibuffer_input"
    vim.bo[self.results_buf].filetype = "minibuffer_results"

    -- Create Results Window
    vim.cmd "botright 10split"
    self.results_win = api.nvim_get_current_win()
    api.nvim_win_set_buf(self.results_win, self.results_buf)

    self:_configure_window(self.results_win)

    -- Create Input Window
    vim.cmd "leftabove 1split"
    self.input_win = api.nvim_get_current_win()
    api.nvim_win_set_buf(self.input_win, self.input_buf)

    self:_configure_window(self.input_win)
    vim.cmd "resize 1"

    api.nvim_buf_set_extmark(self.input_buf, self.prompt_ns, 0, 0, {
        virt_text = { { self.prompt_text, "Title" } },
        virt_text_pos = "inline",
        right_gravity = false,
    })

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

function UI:render(matches, selected_index, marked)
    if #matches == 0 then
        api.nvim_buf_set_lines(self.results_buf, 0, -1, false, { " " })
        return
    end

    api.nvim_buf_set_lines(self.results_buf, 0, -1, false, matches)
    api.nvim_buf_clear_namespace(self.results_buf, self.ns_id, 0, -1)

    for i, line in ipairs(matches) do
        local line_idx = i - 1
        highlight.highlight_entry(self.results_buf, self.ns_id, line_idx, line, i <= 200)

        if marked and marked[line] then
            api.nvim_buf_set_extmark(self.results_buf, self.ns_id, line_idx, 0, {
                sign_text = "●",
                sign_hl_group = "String",
                priority = 105,
            })
        end
    end

    if selected_index > 0 and selected_index <= #matches then
        local selected_text = matches[selected_index]

        api.nvim_buf_set_extmark(self.results_buf, self.ns_id, selected_index - 1, 0, {
            end_row = selected_index - 1,
            end_col = #selected_text,
            hl_group = "Visual",
            priority = 100,
        })
        api.nvim_win_set_cursor(self.results_win, { selected_index, 0 })
    end
end

function UI:set_prompt(text)
    self.prompt_text = text
    if self.input_buf and api.nvim_buf_is_valid(self.input_buf) then
        api.nvim_buf_clear_namespace(self.input_buf, self.prompt_ns, 0, -1)
        api.nvim_buf_set_extmark(self.input_buf, self.prompt_ns, 0, 0, {
            virt_text = { { self.prompt_text, "Title" } },
            virt_text_pos = "inline",
            right_gravity = false,
        })
    end
end

function UI:update_input(lines)
    api.nvim_buf_set_lines(self.input_buf, 0, -1, false, lines)
    api.nvim_win_set_cursor(self.input_win, { 1, #lines[1] })
end

function UI:close()
    if self.results_win and api.nvim_win_is_valid(self.results_win) then
        api.nvim_win_close(self.results_win, true)
    end
    if self.input_win and api.nvim_win_is_valid(self.input_win) then
        api.nvim_win_close(self.input_win, true)
    end
    vim.cmd "stopinsert"
end

return M
