return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  keys = {
    { '<Leader>bn', '<cmd>enew<CR>', desc = 'New buffer' },
    { '<Leader>c', '<cmd>bdelete<CR>', desc = 'Close buffer' },
    { '<Leader>bd', '<cmd>bdelete<CR>', desc = 'Close buffer' },
    { ']b', '<cmd>BufferLineCycleNext<CR>', desc = 'Next buffer' },
    { '[b', '<cmd>BufferLineCyclePrev<CR>', desc = 'Previous buffer' },
    { '<S-Right>', '<cmd>BufferLineCycleNext<CR>', desc = 'Next buffer' },
    { '<S-Left>', '<cmd>BufferLineCyclePrev<CR>', desc = 'Previous buffer' },
  },
  opts = {
    options = {
      close_command = 'bdelete! %d',
      diagnostics = 'nvim_lsp',
      offsets = {
        {
          filetype = 'neo-tree',
          text = 'File Explorer',
          highlight = 'Directory',
          separator = true,
        },
      },
    },
  },
}
