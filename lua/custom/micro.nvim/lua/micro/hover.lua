local M = {}

local eldoc_win_id = nil
local eldoc_buf_id = nil

local function close_eldoc_window()
    pcall(vim.api.nvim_win_close, eldoc_win_id, true)
    pcall(vim.api.nvim_buf_delete, eldoc_buf_id, { force = true }, true)
    eldoc_buf_id = nil
    eldoc_win_id = nil
end

local function eldoc()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients { bufnr = bufnr }

    ---@type boolean
    local has_hover_provider = false
    for _, client in ipairs(clients) do
        if client and client.server_capabilities and client.server_capabilities.hoverProvider then
            has_hover_provider = true
            break
        end
    end

    if not has_hover_provider then
        return
    end

    local handler = function(err, result, _, _)
        if err or not result or not result.contents then
            return
        end

        ---@type string[]
        local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)

        if vim.tbl_isempty(lines) then
            return
        end

        if vim.Micro.hover.layout == "eldoc" then
            if eldoc_win_id and vim.api.nvim_win_is_valid(eldoc_win_id) then
                return
            end

            close_eldoc_window()

            eldoc_buf_id = vim.api.nvim_create_buf(false, true)
            vim.b[eldoc_buf_id].statusline_ignore = true

            vim.api.nvim_buf_set_lines(eldoc_buf_id, 0, 0, false, lines)

            local max_height = math.floor(vim.o.lines * vim.Micro.hover.opts.ratio)
            if vim.Micro.hover.opts.max_height then
                max_height = math.min(max_height, vim.Micro.hover.opts.max_height)
            end

            eldoc_win_id = vim.api.nvim_open_win(eldoc_buf_id, false, {
                split = "below",
                win = -1,
                height = math.min(max_height, #lines),
                style = "minimal",
            })
            vim.api.nvim_buf_set_name(eldoc_buf_id, "[LSP Eldoc]")
            vim.api.nvim_set_option_value("filetype", "markdown", { buf = eldoc_buf_id })
            vim.api.nvim_set_option_value("buftype", "nofile", { buf = eldoc_buf_id })
            vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = eldoc_buf_id })
            vim.api.nvim_set_option_value("modifiable", false, { buf = eldoc_buf_id })
            vim.api.nvim_set_option_value("swapfile", false, { buf = eldoc_buf_id })
            vim.api.nvim_set_option_value("conceallevel", 2, { win = eldoc_win_id })
            vim.api.nvim_win_set_var(eldoc_win_id, "statusline_ignore", true)
            vim.keymap.set("n", "q", close_eldoc_window, {
                buffer = eldoc_buf_id,
                silent = true,
                noremap = true,
                desc = "Close LSP eldoc window",
            })
            return
        elseif vim.Micro.hover.layout == "float" then
            vim.lsp.util.open_floating_preview(lines, "markdown", vim.Micro.hover.opts)
            return
        else
            return
        end
    end

    local params = vim.lsp.util.make_position_params(0, "utf-32")
    vim.lsp.buf_request(bufnr, "textDocument/hover", params, handler)
end

local function toggle_auto_hover()
    if vim.Micro.hover == nil then
        vim.notify("`vim.Micro.hover` doesn't exists!", vim.log.levels.WARN, { title = "LSP" })
        return
    end
    if vim.Micro.hover.enabled == nil then
        vim.notify("`vim.Micro.hover.enabled` doesn't exists!", vim.log.levels.WARN, { title = "LSP" })
        return
    end
    vim.Micro.hover.enabled = not vim.Micro.hover.enabled
    if vim.Micro.hover.enabled then
        vim.notify("Auto Hover enabled", vim.log.levels.INFO, { title = "LSP" })
    else
        vim.notify("Auto Hover disabled", vim.log.levels.INFO, { title = "LSP" })
    end
end

function M.setup(opts)
    local default_opts = {
        enabled = false,
        auto_hover = {
            enabled = false,
            delay = 500,
        },
        layout = "eldoc",
        opts = {
            border = "rounded",
            relative = "editor",
            offset_x = vim.o.columns,
            ratio = 0.1,
            max_height = nil,
        },
    }

    ---@type table
    vim.Micro.hover = vim.tbl_deep_extend("force", default_opts, opts or {})

    vim.o.updatetime = vim.Micro.hover.auto_hover.delay

    local lsp_hover_augroup = vim.api.nvim_create_augroup("LspHoverOnHold", { clear = true })
    local eldoc_close_augroup = vim.api.nvim_create_augroup("LspEldocAutoClose", { clear = true })

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
        group = eldoc_close_augroup,
        callback = function()
            if not eldoc_win_id or not vim.api.nvim_win_is_valid(eldoc_win_id) then
                return
            end
            local current_win = vim.api.nvim_get_current_win()
            if current_win ~= eldoc_win_id then
                close_eldoc_window()
            end
        end,
        desc = "Close LSP eldoc window when cursor moves or context changes",
    })

    vim.api.nvim_create_autocmd("CursorHold", {
        group = lsp_hover_augroup,
        pattern = "*",
        callback = function()
            if not vim.Micro.hover then
                return
            end
            if not vim.Micro.hover.auto_hover.enabled then
                return
            end
            eldoc()
        end,
        desc = "Show LSP hover documentation on CursorHold (silently ignores empty responses)",
    })

    vim.Micro.eldoc = eldoc
end

return M
