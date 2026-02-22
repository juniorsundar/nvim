local M = {}

function M.setup(opts)
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("FoldConfig", { clear = true }),
        callback = function(_)
            vim.o.foldmethod = "expr"
            vim.o.foldcolumn = "0" -- '0' is not bad
            vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
            -- vim.o.foldexpr = "nvim_treesitter#foldexpr()"

            local function fold_virt_text(result, s, lnum, coloff)
                if not coloff then
                    coloff = 0
                end
                local text = ""
                local hl
                for i = 1, #s do
                    local char = s:sub(i, i)
                    local hls = vim.treesitter.get_captures_at_pos(0, lnum, coloff + i - 1)
                    local _hl = hls[#hls]
                    if _hl then
                        local new_hl = "@" .. _hl.capture
                        if new_hl ~= hl then
                            table.insert(result, { text, hl })
                            text = ""
                            hl = nil
                        end
                        text = text .. char
                        hl = new_hl
                    else
                        text = text .. char
                    end
                end
                table.insert(result, { text, hl })
            end

            function _G.custom_foldtext()
                local start = vim.fn.getline(vim.v.foldstart)
                local end_str = vim.fn.getline(vim.v.foldend)
                local end_ = vim.trim(end_str)
                local result = {}
                fold_virt_text(result, start, vim.v.foldstart - 1)
                table.insert(result, { " ... ", "Delimiter" })
                fold_virt_text(result, end_, vim.v.foldend - 1, #(end_str:match "^(%s+)" or ""))
                return result
            end

            vim.opt.foldtext = "v:lua.custom_foldtext()"
        end,
    })
end

return M
