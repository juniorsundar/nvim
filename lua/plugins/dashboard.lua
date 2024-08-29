return {
    'nvimdev/dashboard-nvim',
    -- event = 'VimEnter',
    config = function()
        local fzf = require('fzf-lua')

        local config_path = vim.env.HOME .. '/dotfiles/.config/nvim'

        local config_file_list = function()
            local dirs = vim.split(config_path, ',')
            local list = {}
            for _, dir in pairs(dirs) do
                local p = io.popen('rg --files --hidden ' .. dir)
                if p ~= nil then
                    for file in p:lines() do
                        table.insert(list, file)
                    end
                end
            end
            return list
        end

        local configs = function(opts)
            opts = opts or {}
            local results = config_file_list()

            fzf.fzf_exec(results, {
                prompt = 'find in dotfiles> ',
                previewer = 'builtin',
                actions = {
                    ['default'] = function(selected)
                        vim.cmd('edit ' .. selected[1])
                    end,
                },
            })
        end

        require('dashboard').setup(
            {
                theme = 'hyper',
                config = {
                    week_header = {
                        enable = true,
                    },
                    project = {
                        enable = false,
                    },
                    disable_move = true,
                    shortcut = {
                        {
                            desc = 'New File',
                            group = 'Function',
                            action = 'ene',
                            key = 'e',
                        },
                        {
                            desc = 'Update',
                            group = 'Include',
                            action = 'Lazy update',
                            key = 'u',
                        },
                        {
                            desc = 'Files',
                            group = 'Function',
                            action = 'Telescope find_files layout_strategy=vertical',
                            key = 'f',
                        },
                        {
                            desc = 'Neovim Config',
                            group = 'Constant',
                            action = configs,
                            key = 'c',
                        },
                        {
                            desc = 'Quit',
                            group = 'String',
                            action = 'q!',
                            key = 'q',
                        },
                    },
                },
            }
        )
    end,
}
