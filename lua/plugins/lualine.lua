return {
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            local lualine = require('lualine')

            -- Color table for highlights
            -- stylua: ignore
            local colors = {
                bg       = '#1e2124',
                fg       = '#ffffff',
                yellow   = '#f1ff5e',
                cyan     = '#64d8cb',
                darkblue = '#081633',
                green    = '#5eff6c',
                orange   = '#ffbd5e',
                violet   = '#bd5eff',
                magenta  = '#ff5ef1',
                blue     = '#5ea1ff',
                red      = '#ff6e5e',
            }

            local conditions = {
                buffer_not_empty = function()
                    return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
                end,
                hide_in_width = function()
                    return vim.fn.winwidth(0) > 80
                end,
                check_git_workspace = function()
                    local filepath = vim.fn.expand('%:p:h')
                    local gitdir = vim.fn.finddir('.git', filepath .. ';')
                    return gitdir and #gitdir > 0 and #gitdir < #filepath
                end,
            }

            -- Config
            local config = {
                options = {
                    disabled_filetypes = {
                        "NeogitStatus",
                        "oil",
                        "fzf",
                    },
                    -- Disable sections and component separators
                    component_separators = '',
                    section_separators = '',
                    theme = {
                        -- We are going to use lualine_c an lualine_x as left and
                        -- right section. Both are highlighted by c theme .  So we
                        -- are just setting default looks o statusline
                        normal = { c = { fg = colors.fg, bg = colors.bg } },
                        inactive = { c = { fg = colors.fg, bg = colors.bg } },
                    },
                },
                sections = {
                    -- these are to remove the defaults
                    lualine_a = {},
                    lualine_b = {},
                    lualine_y = {},
                    lualine_z = {},
                    -- These will be filled later
                    lualine_c = {},
                    lualine_x = {},
                },
                inactive_sections = {
                    -- these are to remove the defaults
                    lualine_a = {},
                    lualine_b = {},
                    lualine_y = {},
                    lualine_z = {},
                    lualine_c = {'filename'},
                    lualine_x = {'location'},
                },
            }

            -- Inserts a component in lualine_c at left section
            local function ins_left(component)
                table.insert(config.sections.lualine_c, component)
            end

            -- Inserts a component in lualine_x at right section
            local function ins_right(component)
                table.insert(config.sections.lualine_x, component)
            end

            ins_left {
                function()
                    return ''
                end,
                color = function()
                    -- auto change color according to neovims mode
                    local mode_color = {
                        n = colors.blue,
                        i = colors.red,
                        v = colors.green,
                        [''] = colors.green,
                        V = colors.green,
                        c = colors.magenta,
                        no = colors.red,
                        s = colors.orange,
                        S = colors.orange,
                        [''] = colors.orange,
                        ic = colors.yellow,
                        R = colors.violet,
                        Rv = colors.violet,
                        cv = colors.red,
                        ce = colors.red,
                        r = colors.cyan,
                        rm = colors.cyan,
                        ['r?'] = colors.cyan,
                        ['!'] = colors.red,
                        t = colors.red,
                    }
                    return { bg = mode_color[vim.fn.mode()] }
                end,
                padding = { left = 0, right = 1 }, -- We don't need space before this
            }

            ins_left {
                -- mode component
                -- function()
                --     return ''
                -- end,
                "mode",
                color = function()
                    -- auto change color according to neovims mode
                    local mode_color = {
                        n = colors.blue,
                        i = colors.red,
                        v = colors.green,
                        [''] = colors.green,
                        V = colors.green,
                        c = colors.magenta,
                        no = colors.red,
                        s = colors.orange,
                        S = colors.orange,
                        [''] = colors.orange,
                        ic = colors.yellow,
                        R = colors.violet,
                        Rv = colors.violet,
                        cv = colors.red,
                        ce = colors.red,
                        r = colors.cyan,
                        rm = colors.cyan,
                        ['r?'] = colors.cyan,
                        ['!'] = colors.red,
                        t = colors.red,
                    }
                    return { bg = mode_color[vim.fn.mode()], fg = colors.bg }
                end,
                padding = { left = 1, right = 1 },
            }

            ins_left {
                'branch',
                icon = '',
                color = { fg = colors.violet, gui = 'bold' },
                padding = { left = 1, right = 1 },
            }

            ins_left {
                'diagnostics',
                sources = { 'nvim_diagnostic' },
                symbols = { error = ' ', warn = ' ', info = ' ' },
                diagnostics_color = {
                    error = { fg = colors.red },
                    warn = { fg = colors.yellow },
                    info = { fg = colors.cyan },
                },
            }

            -- ins_left {
            --     'diff',
            --     -- Is it me or the symbol for modified us really weird
            --     symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
            --     diff_color = {
            --         added = { fg = colors.green },
            --         modified = { fg = colors.orange },
            --         removed = { fg = colors.red },
            --     },
            --     cond = conditions.hide_in_width,
            --     padding = { right = 1 }
            -- }

            ins_left {
                'filename',
                cond = conditions.buffer_not_empty,
                color = { fg = colors.fg, gui = 'bold' },
            }


            -- Insert mid section. You can make any number of sections in neovim :)
            -- for lualine it's any number greater then 2
            ins_left {
                function()
                    return '%='
                end,
            }

            -- Add components to right sections
            ins_right {
                'filetype',
                icons_enabled = true, -- I think icons are cool but Eviline doesn't have them. sigh
                color = { gui = 'italic' }
            }

            ins_right { 'location' }

            ins_right { 'progress', color = { fg = colors.fg, gui = 'bold' } }

            ins_right {
                function()
                    return '▊'
                end,
                color = function()
                    -- auto change color according to neovims mode
                    local mode_color = {
                        n = colors.blue,
                        i = colors.red,
                        v = colors.green,
                        [''] = colors.green,
                        V = colors.green,
                        c = colors.magenta,
                        no = colors.red,
                        s = colors.orange,
                        S = colors.orange,
                        [''] = colors.orange,
                        ic = colors.yellow,
                        R = colors.violet,
                        Rv = colors.violet,
                        cv = colors.red,
                        ce = colors.red,
                        r = colors.cyan,
                        rm = colors.cyan,
                        ['r?'] = colors.cyan,
                        ['!'] = colors.red,
                        t = colors.red,
                    }
                    return { fg = mode_color[vim.fn.mode()] }
                end,
                padding = { left = 1 },
            }

            -- Now don't forget to initialize lualine
            lualine.setup(config)
        end
    }
}
