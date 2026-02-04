vim.api.nvim_create_user_command("GrepTest", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "init.lua:1:1:-- OPTIONS ==========================================================",
        "lua/custom/buffers.nvim/lua/buffers/grep.lua:15:1:local function parse_line(line)",
        -- Test with no extension (might fail TS)
        "Makefile:10:5:clean:",
        -- Test non-existent file
        "fake_file.js:10:10:console.log('hello')",
    })
    vim.bo[buf].filetype = "grep"
    vim.cmd.buffer(buf)
end, {})
