return {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  version = false,
  build = 'make',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-tree/nvim-web-devicons',
    'HakonHarnes/img-clip.nvim',
    'MeanderingProgrammer/render-markdown.nvim',
  },
  opts = {
    provider = 'copilot',
  },
}
