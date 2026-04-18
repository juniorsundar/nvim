local M = {}
local fn = vim.fn

-- Ensure syntax highlighting is enabled globally
vim.cmd "syntax enable"

function _G.qftf(info)
    local items
    local ret = {}
    -- The name of item in list is based on the directory of quickfix window.
    -- Change the directory for quickfix window make the name of item shorter.
    -- It's a good opportunity to change current directory in quickfixtextfunc :)
    --
    -- local alterBufnr = fn.bufname('#') -- alternative buffer is the buffer before enter qf window
    -- local root = getRootByAlterBufnr(alterBufnr)
    -- vim.cmd(('noa lcd %s'):format(fn.fnameescape(root)))
    --
    if info.quickfix == 1 then
        items = fn.getqflist({ id = info.id, items = 0 }).items
    else
        items = fn.getloclist(info.winid, { id = info.id, items = 0 }).items
    end
    local limit = 50
    local fnameFmt1, fnameFmt2 = "%-" .. limit .. "s", "…%." .. (limit - 1) .. "s"
    local validFmt = "%s │%5d:%-3d│%s %s"
    for i = info.start_idx, info.end_idx do
        local e = items[i]
        local fname = ""
        local str
        if e.valid == 1 then
            if e.bufnr > 0 then
                fname = fn.bufname(e.bufnr)
                if fname == "" then
                    fname = "[No Name]"
                else
                    fname = fname:gsub("^" .. vim.env.HOME, "~")
                end
                if #fname <= limit then
                    fname = fnameFmt1:format(fname)
                else
                    fname = fnameFmt2:format(fname:sub(1 - limit))
                end
            end
            local lnum = e.lnum > 99999 and -1 or e.lnum
            local col = e.col > 999 and -1 or e.col
            local qtype = e.type == "" and "" or " " .. e.type:sub(1, 1):upper()
            str = validFmt:format(fname, lnum, col, qtype, e.text)
        else
            str = e.text
        end
        table.insert(ret, str)
    end
    return ret
end

vim.o.qftf = "{info -> v:lua._G.qftf(info)}"

-- Custom quickfix syntax integration
local qf_augroup = vim.api.nvim_create_augroup("CustomQfSyntax", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    group = qf_augroup,
    callback = function()
        -- Use a custom guard to avoid conflicts with Neovim's default qf syntax
        if vim.b.qf_custom_syntax_loaded then
            return
        end

        -- Clear default quickfix syntax to prevent rule conflicts
        vim.cmd "syntax clear"

        vim.cmd [[
            syntax match qfFileName /^[^│]*/ nextgroup=qfSeparatorLeft
            syntax match qfSeparatorLeft /│/ contained nextgroup=qfLineNr
            syntax match qfLineNr /[^│]*/ contained nextgroup=qfSeparatorRight
            syntax match qfSeparatorRight '│' contained nextgroup=qfError,qfWarning,qfInfo,qfNote
            syntax match qfError / E .*$/ contained
            syntax match qfWarning / W .*$/ contained
            syntax match qfInfo / I .*$/ contained
            syntax match qfNote / [NH] .*$/ contained

            highlight default link qfFileName Directory
            highlight default link qfSeparatorLeft Delimiter
            highlight default link qfSeparatorRight Delimiter
            highlight default link qfLineNr LineNr
            highlight default link qfError DiagnosticError
            highlight default link qfWarning DiagnosticWarn
            highlight default link qfInfo DiagnosticInfo
            highlight default link qfNote DiagnosticHint
        ]]

        vim.b.qf_custom_syntax_loaded = true
    end,
})

return M
