local M = {}

M.last_cmd = nil
M.last_cwd = nil
M.compile_window = nil

M.close_compile_window = function()
    vim.api.nvim_win_close(M.compile_window, true)
    M.compile_window = nil
end

M.command = function()
    local cmd = vim.fn.input('Compile command: ', M.last_cmd or "")

    if cmd == nil or cmd == "" then
        vim.notify("Compilation cancelled", vim.log.levels.WARN)
        return
    end

    local default_cwd = M.last_cwd or vim.fn.getcwd()
    local cwd = vim.fn.input('CWD: ', default_cwd)

    if cwd == nil or cwd == "" then
        vim.notify("Compilation cancelled", vim.log.levels.WARN)
        return
    end

    M.executor(cmd, cwd)
end

M.run_last = function()
    if not M.last_cmd then
        vim.notify("No last command to run. Use :Compile first.", vim.log.levels.ERROR)
        return
    end
    M.executor(M.last_cmd, M.last_cwd)
end


M.executor = function(cmd, cwd)
    if M.compile_window ~= nil then
        M.close_compile_window()
    end

    if not cmd then
        vim.notify("No command to execute", vim.log.levels.ERROR)
        return
    end
    M.last_cmd = cmd
    M.last_cwd = cwd

    local original_window = vim.api.nvim_get_current_win()
    local compile_buffer = vim.api.nvim_create_buf(false, true)
    M.compile_window = vim.api.nvim_open_win(compile_buffer, true, {
        split = "below",
        win = -1,
        height = math.floor(vim.o.lines * 0.5),
        style = "minimal",
    })
    local actual_cwd = cwd or vim.fn.getcwd()
    local cmd_table = vim.split(cmd, " ", { trimempty = false })

    if not cmd or cmd == "" then
        vim.notify("Error: 'cmd' is required.", vim.log.levels.ERROR)
        return
    end

    vim.api.nvim_buf_set_keymap(compile_buffer, "n", "<CR>", "", {
        callback = function()
            local line = vim.api.nvim_get_current_line()
            local cfile = vim.fn.expand("<cfile>")
            local start_idx = line:find(cfile, 1, true)
            if not start_idx then
                print("Path not found on current line")
                return
            end
            local after_path = line:sub(start_idx + #cfile)
            local colon_num_match = after_path:match("^%s*:(%d+)")
            local lnum = 1
            if colon_num_match then
                lnum = tonumber(colon_num_match)
            end

            local full_path = vim.fs.normalize(vim.fs.joinpath(actual_cwd, cfile))
            if not vim.uv.fs_stat(full_path) and vim.uv.fs_stat(cfile) then
                full_path = vim.fs.normalize(cfile)
            end
            if not vim.uv.fs_stat(full_path) then
                return nil
            end

            if not vim.api.nvim_win_is_valid(original_window) then
                vim.notify("Original window is no longer valid", vim.log.levels.ERROR)
                return
            end

            vim.fn.win_execute(original_window, "edit +" .. lnum .. " " .. vim.fn.fnameescape(full_path))
            vim.api.nvim_set_current_win(original_window)
        end,
        noremap = true,
        silent = true,
    })
    vim.api.nvim_buf_set_keymap(compile_buffer, "n", "q", "", {
        callback = function()
            M.close_compile_window()
        end,
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_name(compile_buffer, "[Compile]")
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = compile_buffer })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = compile_buffer })
    vim.api.nvim_set_option_value("swapfile", false, { buf = compile_buffer })

    local on_data = function(err, data)
        if err then
            vim.schedule(function()
                vim.api.nvim_buf_set_lines(compile_buffer, -1, -1, false, { "[Stream error: " .. err .. "]" })
            end)
            return
        end
        if data == nil then
            return
        end
        vim.schedule(function()
            local lines = vim.split(data, "\n", { trimempty = false })
            vim.api.nvim_buf_set_lines(compile_buffer, -1, -1, false, lines)
        end)
    end

    local on_exit = function(obj)
        vim.schedule(function()
            local status_line = "[Command finished with code " .. obj.code .. "]"
            vim.api.nvim_buf_set_lines(compile_buffer, -1, -1, false, { "", status_line })
        end)
    end

    vim.system(cmd_table, {
        cwd = actual_cwd,
        text = true,
        stdout = on_data,
        stderr = on_data
    }, on_exit)
end

vim.api.nvim_create_user_command("Compile", M.command, {})
vim.api.nvim_create_user_command("CompileLast", M.run_last, {})
