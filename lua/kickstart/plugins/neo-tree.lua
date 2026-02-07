-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  init = function()
    -- Auto-close Neovim if Neo-tree is the last window
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('NeoTreeAutoClose', { clear = true }),
      callback = function()
        local layout = vim.fn.winlayout()
        if layout[1] == 'leaf' and vim.bo[vim.api.nvim_win_get_buf(layout[2])].filetype == 'neo-tree' then
          vim.cmd 'quit'
        end
      end,
    })
  end,
  opts = {
    window = {
      position = 'right',
    },
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['l'] = 'open',
          ['<Right>'] = 'open',
          ['h'] = 'close_node',
          ['<Left>'] = 'close_node',
        },
      },
    },
  },
}
