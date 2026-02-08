return {
  'folke/trouble.nvim',
  cmd = 'Trouble',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  keys = {
    { '<Leader>xX', '<cmd>Trouble diagnostics toggle<CR>', desc = 'Trouble: workspace diagnostics' },
    { '<Leader>xx', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>', desc = 'Trouble: document diagnostics' },
    { '<Leader>xL', '<cmd>Trouble loclist toggle<CR>', desc = 'Trouble: location list' },
    { '<Leader>xQ', '<cmd>Trouble qflist toggle<CR>', desc = 'Trouble: quickfix list' },
    { '<Leader>xt', '<cmd>Trouble todo toggle<CR>', desc = 'Trouble: todo comments' },
    { '<Leader>xT', '<cmd>Trouble todo toggle filter={tag={TODO,FIX,FIXME}}<CR>', desc = 'Trouble: todo/fix/fixme' },
  },
  opts = {
    keys = {
      ['<ESC>'] = 'close',
      ['q'] = 'close',
      ['<C-e>'] = 'close',
    },
  },
}
