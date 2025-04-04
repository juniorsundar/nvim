return {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' }, -- if you use the mini.nvim suite
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    -- opts = {},
    config = function ()
        require('render-markdown').setup({
            completions = { blink = { enabled = true } },
        })
    end
}
