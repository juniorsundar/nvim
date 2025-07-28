local Snacks = require "snacks"

local M = {}

local function get_tabs()
  local tabs = {}
  local tabpages = vim.api.nvim_list_tabpages()
  for i, tabpage in ipairs(tabpages) do
    local wins = vim.api.nvim_tabpage_list_wins(tabpage)
    local cur_win = vim.api.nvim_tabpage_get_win(tabpage)
    local buf = vim.api.nvim_win_get_buf(cur_win)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    if name == "" then
      name = "[No Name]"
    end

    local preview_lines = {}
    table.insert(preview_lines, ("Tab %d: %d window%s"):format(i, #wins, #wins == 1 and "" or "s"))
    table.insert(preview_lines, ("%-6s %-8s %s"):format("WinID", "Buf#", "File"))
    table.insert(preview_lines, string.rep("-", 40))
    for _, win in ipairs(wins) do
      local win_buf = vim.api.nvim_win_get_buf(win)
      local bufname = vim.api.nvim_buf_get_name(win_buf)
      if bufname == "" then
        bufname = "[No Name]"
      end
      bufname = vim.fn.fnamemodify(bufname, ":~:.") -- relative to cwd, or ~
      local win_marker = (win == cur_win) and "->" or "  "
      table.insert(preview_lines, ("%s %-6d %-8d %s"):format(win_marker, win, win_buf, bufname))
    end
    if #wins == 0 then
      table.insert(preview_lines, "No windows in tab")
    end

    table.insert(tabs, {
      idx = i,
      text = ("Tab %d: %s"):format(i, name),
      tabnr = i,
      tabpage = tabpage,
      preview = {
        text = table.concat(preview_lines, "\n"),
        ft = "text",
      },
    })
  end
  return tabs
end

function M.tabs_picker()
  local items = get_tabs()
  Snacks.picker {
    title = "Tabs",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      vim.cmd(("tabnext %d"):format(item.tabnr))
    end,
    preview = "preview",
    actions = {
      close_tab = function(picker, item)
        picker:close()
        vim.cmd(("tabclose %d"):format(item.tabnr))
      end,
    },
    win = {
      input = {
        keys = {
          ["d"] = "close_tab",
        },
      },
    },
  }
end

return M
