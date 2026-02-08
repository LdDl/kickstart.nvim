-- Store last test command for re-run (module-level so it persists)
local last_test_cmd = nil

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

-- Close existing test output window if any
local function close_test_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.w[win].is_go_test then
      vim.api.nvim_win_close(win, true)
      return true
    end
  end
  return false
end

-- Run a go test command in a terminal split at the bottom
local function run_test(cmd)
  close_test_win()
  last_test_cmd = cmd
  vim.cmd 'botright new | resize 15'
  vim.w[vim.api.nvim_get_current_win()].is_go_test = true
  vim.fn.termopen(cmd)
  local buf = vim.api.nvim_get_current_buf()
  -- q closes the test output (press Esc first if cursor is in the terminal)
  vim.keymap.set('n', 'q', function() close_test_win() end, { buffer = buf, nowait = true })
  -- Return focus to code window
  vim.cmd 'wincmd p'
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
            local test_cmd = string.format('go test -v -count=1 -run "^%s$" .', name)
            run_test(string.format("cd %s && echo '$ %s' && echo '' && %s", vim.fn.shellescape(dir), test_cmd, test_cmd))
          end, 'Test: run nearest')

          -- Run all tests in current file only
          buf_map('<Leader>tf', function()
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
            if #tests == 0 then
              vim.notify('No test functions found in this file', vim.log.levels.WARN)
              return
            end
            local dir = vim.fn.expand '%:p:h'
            local pattern = '^(' .. table.concat(tests, '|') .. ')$'
            local test_cmd = string.format('go test -v -count=1 -run "%s" .', pattern)
            run_test(string.format("cd %s && echo '$ %s' && echo '' && %s", vim.fn.shellescape(dir), test_cmd, test_cmd))
          end, 'Test: run file')

          -- Run all tests in project
          buf_map('<Leader>ta', function()
            local dir = vim.fn.expand '%:p:h'
            local test_cmd = 'go test -v -count=1 ./...'
            run_test(string.format("cd %s && echo '$ %s' && echo '' && %s", vim.fn.shellescape(dir), test_cmd, test_cmd))
          end, 'Test: run all')

          -- Re-run last test
          buf_map('<Leader>tl', function()
            if last_test_cmd then
              run_test(last_test_cmd)
            else
              vim.notify('No previous test run', vim.log.levels.WARN)
            end
          end, 'Test: re-run last')

          -- Toggle test output window
          buf_map('<Leader>to', function()
            close_test_win()
          end, 'Test: close output')

          -- Stop running test
          buf_map('<Leader>tx', function()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.w[win].is_go_test then
                local buf = vim.api.nvim_win_get_buf(win)
                local job_id = vim.b[buf].terminal_job_id
                if job_id then
                  vim.fn.jobstop(job_id)
                end
                return
              end
            end
          end, 'Test: stop')
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
