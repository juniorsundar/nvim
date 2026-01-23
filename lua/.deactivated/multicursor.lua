MiniDeps.later(function()
    MiniDeps.add { source = "jake-stewart/multicursor.nvim" }

    local mc = require "multicursor-nvim"
    mc.setup()

    local set = vim.keymap.set

    local function stop_multicursor_layer()
        pcall(vim.keymap.del, { "n", "x" }, "<up>")
        pcall(vim.keymap.del, { "n", "x" }, "<down>")
        pcall(vim.keymap.del, { "n", "x" }, "<C-up>")
        pcall(vim.keymap.del, { "n", "x" }, "<C-down>")
        pcall(vim.keymap.del, { "n", "x" }, "n")
        pcall(vim.keymap.del, { "n", "x" }, "N")
        pcall(vim.keymap.del, { "n", "x" }, "s")
        pcall(vim.keymap.del, { "n", "x" }, "S")
        pcall(vim.keymap.del, { "n", "x" }, "<C-c><C-c>")
        print "Multicursor Layer: OFF"
    end

    local function start_multicursor_layer()
        set({ "n", "x" }, "<up>", function()
            mc.lineAddCursor(-1)
        end)
        set({ "n", "x" }, "<down>", function()
            mc.lineAddCursor(1)
        end)
        set({ "n", "x" }, "<C-up>", function()
            mc.lineSkipCursor(-1)
        end)
        set({ "n", "x" }, "<C-down>", function()
            mc.lineSkipCursor(1)
        end)
        set({ "n", "x" }, "n", function()
            mc.matchAddCursor(1)
        end)
        set({ "n", "x" }, "N", function()
            mc.matchAddCursor(-1)
        end)
        set({ "n", "x" }, "s", function()
            mc.matchSkipCursor(1)
        end)
        set({ "n", "x" }, "S", function()
            mc.matchSkipCursor(-1)
        end)
        set({ "n", "x" }, "<C-c><C-c>", stop_multicursor_layer)
        print "Multicursor Layer: ON - Press <C-c><C-c> to exit"
    end

    set({ "n", "x" }, "<leader>m", start_multicursor_layer)

    -- Add and remove cursors with control + left click.
    set("n", "<c-leftmouse>", mc.handleMouse)
    set("n", "<c-leftdrag>", mc.handleMouseDrag)
    set("n", "<c-leftrelease>", mc.handleMouseRelease)

    -- Disable and enable cursors.
    set({ "n", "x" }, "<c-q>", mc.toggleCursor)

    -- Mappings defined in a keymap layer only apply when there are
    -- multiple cursors. This lets you have overlapping mappings.
    mc.addKeymapLayer(function(layerSet)
        -- Select a different cursor as the main one.
        layerSet({ "n", "x" }, "<left>", mc.prevCursor)
        layerSet({ "n", "x" }, "<right>", mc.nextCursor)

        -- Delete the main cursor.
        layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

        layerSet("n", "<esc>", function()
            if not mc.cursorsEnabled() then
                mc.enableCursors()
            else
                mc.clearCursors()
            end
        end)
    end)
end)
