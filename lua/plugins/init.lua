local config_path = vim.fn.stdpath('config')
local plugins_dir = config_path .. '/lua/plugins'

for file_name, file_type in vim.fs.dir(plugins_dir) do
    if file_type == 'file' then
        local module_name = string.match(file_name, "^(.-)%.lua$")
        if module_name and module_name ~= 'init' then
            local require_path = 'plugins.' .. module_name
            local ok, err = pcall(require, require_path)
            if not ok then
                vim.notify(
                    "Error loading plugin config: " .. require_path .. "\n" .. err,
                    vim.log.levels.ERROR
                )
            end
        end
    end
end
