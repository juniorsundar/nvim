local Editor = require "tests.support.editor"

describe("micro.statusline", function()
    local ed

    before_each(function()
        ed = Editor.new()
        ed:lua [[
            package.preload["nvim-web-devicons"] = function() -- not installed in the test editor
                return { get_icon = function() return "F", "Normal" end, get_icon_color = function() return "F", "#ffffff" end }
            end
            vim.o.laststatus = 2
            require("micro.statusline").setup {}
        ]]
    end)
    after_each(function()
        ed:close()
    end)

    -- Screen row of the top border of the statusline float attached to `win`.
    local function float_top(win)
        return ed:lua(
            [[
            local win = ...
            for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                local c = vim.api.nvim_win_get_config(w)
                if c.relative == "win" and c.win == win then
                    return vim.fn.win_screenpos(w)[1]
                end
            end
        ]],
            win
        )
    end

    -- Last text row of `win`; the float's border covers it and its text sits on the statusline row below.
    local function last_text_row(win)
        return ed:lua("local i = vim.fn.getwininfo(...)[1]; return i.winrow + i.winbar + i.height - 1", win)
    end

    for _, winbar in ipairs { false, true } do
        it(("stays inside its window when stacked splits %s a winbar"):format(winbar and "have" or "lack"), function()
            local wins = ed:lua(
                [[
                vim.cmd "split"
                local wins = vim.tbl_filter(function(w)
                    return vim.api.nvim_win_get_config(w).relative == ""
                end, vim.api.nvim_tabpage_list_wins(0))
                for _, w in ipairs(wins) do
                    if ... then vim.wo[w].winbar = "BAR" end
                end
                require("micro.statusline").update()
                return wins
            ]],
                winbar
            )
            ed:wait(("#vim.api.nvim_tabpage_list_wins(0) == %d"):format(#wins * 2))
            for _, w in ipairs(wins) do
                assert.equals(last_text_row(w), float_top(w), "statusline of window " .. w .. " is misplaced")
            end
        end)
    end
end)
