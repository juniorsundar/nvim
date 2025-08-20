return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  branch = 'main',
  build = ':TSUpdate',
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'rust', 'c3', 'c', 'cpp', 'python', 'lua', 'markdown' },
      callback = function()
        vim.treesitter.start()
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      end,
    })
  end
}
