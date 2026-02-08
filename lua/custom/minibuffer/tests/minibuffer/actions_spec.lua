local minibuffer = require "minibuffer"
local Picker = require "minibuffer.picker"
local stub = require "luassert.stub"

describe("minibuffer.actions", function()
    local picker

    before_each(function()
        -- Create a dummy picker.
        -- We pass empty list, as we will inject state manually.
        picker = minibuffer.pick({}, function() end)
    end)

    after_each(function()
        if picker then
            picker:close()
        end
    end)

    it("toggle_mark marks the current item and advances", function()
        picker.current_matches = { "item1", "item2" }
        picker.selected_index = 1

        picker.actions.toggle_mark()

        assert.is_true(picker.marked["item1"])
        assert.are.same(2, picker.selected_index)

        -- Toggle off
        picker.selected_index = 1
        picker.actions.toggle_mark()
        assert.is_false(picker.marked["item1"])
    end)

    describe("send_to_qf", function()
        before_each(function()
            stub(vim.fn, "setqflist")
            stub(vim.cmd, "copen")
        end)

        after_each(function()
            vim.fn.setqflist:revert()
            vim.cmd.copen:revert()
        end)

        it("sends marked items to quickfix", function()
            picker.marked = { ["file1:1:1"] = true, ["file2:2:2"] = true }
            picker.current_matches = { "file1:1:1", "file2:2:2", "file3:3:3" }

            -- We need a parser for them to be useful in QF, but even without, they go as text
            picker.actions.send_to_qf()

            assert.stub(vim.fn.setqflist).was_called()
            -- Check the arguments passed to setqflist.
            -- The second arg is ' ', third is { title = ..., items = ... }
            local call = vim.fn.setqflist.calls[1]
            local what = call.refs[3]

            assert.are.same("Minibuffer Selection", what.title)
            assert.are.same(2, #what.items)
        end)

        it("sends current selection if nothing marked", function()
            picker.marked = {}
            picker.current_matches = { "file1" }
            picker.selected_index = 1

            picker.actions.send_to_qf()

            local call = vim.fn.setqflist.calls[1]
            local what = call.refs[3]
            assert.are.same(1, #what.items)
            assert.are.same("file1", what.items[1].text)
        end)
    end)

    describe("select_input", function()
        it("calls on_select with raw input", function()
            local selected
            picker.on_select = function(sel)
                selected = sel
            end

            -- Mock input line
            vim.api.nvim_buf_set_lines(picker.input_buf, 0, -1, false, { "custom input" })

            picker.actions.select_input()

            assert.are.same("custom input", selected)
        end)
    end)
end)
