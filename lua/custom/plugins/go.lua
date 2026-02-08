-- Find nearest Go test function by searching backwards from cursor
local function get_nearest_test()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  for i = cursor_line, 1, -1 do
    local name = lines[i]:match '^func (Test%w+)'
      or lines[i]:match '^func (Benchmark%w+)'
      or lines[i]:match '^func (Example%w+)'
    if name then
      return name
    end
  end
  return nil
end

-- Collect all test function names from current buffer
local function get_all_tests_in_file()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local tests = {}
  for _, line in ipairs(lines) do
    local name = line:match '^func (Test%w+)'
      or line:match '^func (Benchmark%w+)'
      or line:match '^func (Example%w+)'
    if name then
      table.insert(tests, name)
    end
  end
  return tests
end

return {
  -- Go code generation: gotests, iferr, impl, gomodifytags
  {
    'olexsmir/gopher.nvim',
    ft = 'go',
    build = function()
      if not require('lazy.core.config').spec.plugins['mason.nvim'] then
        vim.print 'Installing go dependencies...'
        vim.cmd.GoInstallDeps()
      end
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('gopher').setup {}

      -- Go test runner keybindings (terminal-based, VS Code-like)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'go',
        group = vim.api.nvim_create_augroup('GoTestKeymaps', { clear = true }),
        callback = function(ev)
          local runner = require 'custom.test-runner'
          local function buf_map(key, fn, desc)
            vim.keymap.set('n', key, fn, { buffer = ev.buf, desc = desc })
          end

          -- Run nearest test
          buf_map('<Leader>tr', function()
            local name = get_nearest_test()
            if not name then
              vim.notify('No test function found at cursor', vim.log.levels.WARN)
              return
            end
            local dir = vim.fn.expand '%:p:h'
            runner.run(string.format('go test -v -count=1 -run "^%s$" .', name), dir)
          end, 'Test: run nearest')

          -- Run all tests in current file only
          buf_map('<Leader>tf', function()
            local tests = get_all_tests_in_file()
            if #tests == 0 then
              vim.notify('No test functions found in this file', vim.log.levels.WARN)
              return
            end
            local dir = vim.fn.expand '%:p:h'
            local pattern = '^(' .. table.concat(tests, '|') .. ')$'
            runner.run(string.format('go test -v -count=1 -run "%s" .', pattern), dir)
          end, 'Test: run file')

          -- Run all tests in project
          buf_map('<Leader>ta', function()
            local dir = vim.fn.expand '%:p:h'
            runner.run('go test -v -count=1 ./...', dir)
          end, 'Test: run all')

          -- Common: rerun, close, stop
          runner.bind_common(ev.buf)
        end,
      })
    end,
  },

  -- Go treesitter parsers
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'go', 'gomod', 'gosum', 'gowork' })
      end
    end,
  },

  -- Go file icons
  {
    'echasnovski/mini.icons',
    opts = {
      file = {
        ['.go-version'] = { glyph = '', hl = 'MiniIconsBlue' },
      },
      filetype = {
        gotmpl = { glyph = '󰟓', hl = 'MiniIconsGrey' },
      },
    },
  },
}
