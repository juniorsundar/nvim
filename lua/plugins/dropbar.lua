return {
    'Bekaboo/dropbar.nvim',
    config = function()
        local dropbar_api = require('dropbar.api')
        vim.keymap.set('n', '<Leader>L;', dropbar_api.pick, { desc = 'Dropbor' })
        vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
        vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
    end
}
