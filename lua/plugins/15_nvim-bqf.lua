MiniDeps.add { source = "kevinhwang91/nvim-bqf" }
local fn = vim.fn

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
    local limit = 31
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

require("bqf").setup {
    auto_resize_height = true,
    preview = {
        border = "solid",
        winblend = 0,
    },
    filter = {
        fzf = {
            extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│" },
        },
    },
}

vim.api.nvim_set_hl(0, "BqfPreviewFloat", { link = "NormalFloat" })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
        local function fix_preview_hl()
            local has_win, winid = pcall(function()
                return require("bqf.preview.floatwin").winid
            end)
            if has_win and winid and vim.api.nvim_win_is_valid(winid) then
                local winhl = vim.wo[winid].winhighlight
                if not winhl:match "LineNr:" then
                    vim.wo[winid].winhighlight = winhl .. ",LineNr:BqfPreviewFloat"
                end
            end
        end

        for _, delay in ipairs { 50, 100, 200, 300, 400 } do
            vim.defer_fn(fix_preview_hl, delay)
        end

        vim.api.nvim_create_autocmd("CursorMoved", {
            buffer = 0,
            callback = function()
                for _, delay in ipairs { 50, 100, 200 } do
                    vim.defer_fn(fix_preview_hl, delay)
                end
            end,
        })
    end,
})
