local capabilities = require "config.lsp.serve_capabilities"
local zig_binary = vim.fn.exepath "zig"

return {
    cmd = { "zls" },
    filetypes = { "zig" },
    root_markers = { "zls.json", "build.zig", ".git" },
    single_file_support = true,
    capabilities = capabilities,
    settings = {
        zls = {
            zig_exe_path = zig_binary,
            enable_build_on_save = true,
        },
    },
}
