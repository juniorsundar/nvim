local Editor = require "tests.support.editor"

describe("micro.completion (kind icons)", function()
    local ed, dir

    before_each(function()
        dir = vim.fn.tempname()
        vim.fn.mkdir(dir .. "/sub", "p")
        vim.fn.writefile({}, dir .. "/alpha.txt")
        ed = Editor.new()
        ed:lua("vim.cmd.cd(...)", dir)
    end)
    after_each(function()
        ed:close()
        vim.fn.delete(dir, "rf")
    end)

    -- "word|kind|kind_hlgroup|menu" for every visible item. On 0.12.5 complete_info() omits
    -- kind_hlgroup, so the highlight is only checked where it is reported.
    local function items()
        return ed:lua [[
            return vim.tbl_map(function(i)
                return table.concat({ i.word, i.kind, i.kind_hlgroup or "?", i.menu }, "|")
            end, vim.fn.complete_info({ "items" }).items)
        ]]
    end
    local reports_hl = vim.fn.has "nvim-0.13" == 1

    local function lsp_item(list)
        for _, i in ipairs(list) do
            if vim.startswith(i, "LspThing|") then
                return vim.split(i, "|", { plain = true })
            end
        end
    end

    it("leaves native kind names when icons are off (default)", function()
        ed:session { server = { delays = { 20 } } }
        ed:input "iTh"
        ed:wait "#vim.fn.complete_info({'items'}).items >= 2"
        local item = lsp_item(items())
        assert.equals("Function", item[2])
    end)

    it("swaps LSP kinds for glyphs linked to treesitter groups and keeps native detail", function()
        ed:session { micro = { icons = true }, server = { delays = { 20 } } }
        ed:input "iTh"
        ed:wait "#vim.fn.complete_info({'items'}).items >= 2"
        local item = lsp_item(items())
        assert.equals("󰊕", item[2])
        if reports_hl then
            assert.equals("MicroKindFunction", item[3])
        end
        assert.same(
            { link = "@function", default = true },
            ed:lua "return vim.api.nvim_get_hl(0, { name = 'MicroKindFunction' })"
        )
        assert.is_true(vim.tbl_contains(items(), "BufThing|||") or vim.tbl_contains(items(), "BufThing||?|"))
    end)

    it("applies user overrides", function()
        ed:session { micro = { icons = { Function = "F" } }, server = { delays = { 20 } } }
        ed:input "iTh"
        ed:wait "#vim.fn.complete_info({'items'}).items >= 2"
        assert.equals("F", lsp_item(items())[2])
    end)

    it("decorates path items", function()
        ed:session { lines = { 'open("' }, row = 1, micro = { icons = true }, server = { delays = { 20 } } }
        ed:input "A./"
        ed:wait "#vim.fn.complete_info({'items'}).items == 2"
        local got = items()
        table.sort(got)
        local hl = reports_hl and { "MicroKindFile", "MicroKindFolder" } or { "?", "?" }
        assert.same({ "alpha.txt|󰈙|" .. hl[1] .. "|[path]", "sub/|󰉋|" .. hl[2] .. "|[path]" }, got)
    end)

    it("keeps LSP icons after routing to a path context and back", function()
        ed:session { lines = { "", "" }, row = 2, micro = { icons = true }, server = { delays = { 20 } } }
        ed:input 'i"./'
        ed:wait "vim.b.micro_completion_route == 'path'"
        ed:input "<C-e><C-u>Th"
        ed:wait "vim.b.micro_completion_route == 'language'"
        ed:wait "#vim.fn.complete_info({'items'}).items >= 1"
        ed:wait "vim.tbl_contains(vim.tbl_map(function(i) return i.kind end, vim.fn.complete_info({'items'}).items), '󰊕')"
    end)

    it("restores highlight links after a colorscheme change", function()
        ed:session { micro = { icons = true }, server = { delays = { 20 } } }
        ed:lua "vim.cmd.colorscheme('default')"
        assert.same(
            { link = "Directory", default = true },
            ed:lua "return vim.api.nvim_get_hl(0, { name = 'MicroKindFolder' })"
        )
    end)
end)
