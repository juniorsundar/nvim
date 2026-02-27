local config_path = vim.fn.stdpath "config"
local plugins_dir = config_path .. "/lua/plugins"
local files = {}

if vim.g.vscode then
    files = {
        "06_nvim-surround",
        "08_flash",
        "09_mini",
    }
else
    for file_name, file_type in vim.fs.dir(plugins_dir) do
        if file_type == "file" then
            local module_name = string.match(file_name, "^(.-)%.lua%")
            if module_name and module_name ~= "init" then
                table.insert(files, module_name)
            end
        end
    end
end

table.sort(files)

for _, module_name in ipairs(files) do
    local require_path = "plugins." .. module_name
    local ok, err = pcall(require, require_path)
    if not ok then
        vim.notify("Error loading plugin config: " .. require_path .. "\n" .. err, vim.log.levels.ERROR)
    end
end
