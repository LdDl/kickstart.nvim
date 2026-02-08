-- Find nearest Rust test function by searching backwards for #[test] + fn name
local function get_nearest_test()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  -- Search backwards from cursor for a fn preceded by #[test]
  for i = cursor_line, 1, -1 do
    local fn_name = lines[i]:match '^%s*fn ([%w_]+)%s*%('
      or lines[i]:match '^%s*async fn ([%w_]+)%s*%('
      or lines[i]:match '^%s*pub fn ([%w_]+)%s*%('
      or lines[i]:match '^%s*pub async fn ([%w_]+)%s*%('
    if fn_name then
      -- Check lines above for #[test] or #[tokio::test]
      for j = i - 1, math.max(1, i - 5), -1 do
        if lines[j]:match '#%[test%]' or lines[j]:match '#%[tokio::test%]' then
          return fn_name
        end
        -- Stop searching if we hit another fn or a blank line gap
        if lines[j]:match '^%s*fn ' or lines[j]:match '^%s*pub fn ' or lines[j]:match '^}' then
          break
        end
      end
    end
  end
  return nil
end

-- Collect all test function names from current buffer
local function get_all_tests_in_file()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local tests = {}
  for i, line in ipairs(lines) do
    local fn_name = line:match '^%s*fn ([%w_]+)%s*%('
      or line:match '^%s*async fn ([%w_]+)%s*%('
      or line:match '^%s*pub fn ([%w_]+)%s*%('
      or line:match '^%s*pub async fn ([%w_]+)%s*%('
    if fn_name then
      for j = i - 1, math.max(1, i - 5), -1 do
        if lines[j]:match '#%[test%]' or lines[j]:match '#%[tokio::test%]' then
          table.insert(tests, fn_name)
          break
        end
        if lines[j]:match '^%s*fn ' or lines[j]:match '^%s*pub fn ' or lines[j]:match '^}' then
          break
        end
      end
    end
  end
  return tests
end

-- Find Cargo.toml directory (project root)
local function find_cargo_root()
  local path = vim.fn.expand '%:p:h'
  while path and path ~= '/' do
    if vim.fn.filereadable(path .. '/Cargo.toml') == 1 then
      return path
    end
    path = vim.fn.fnamemodify(path, ':h')
  end
  return nil
end

return {
  -- Rustaceanvim: rust-analyzer, clippy, codelldb, all-in-one
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
    lazy = false,
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ['rust-analyzer'] = {
              check = {
                command = 'clippy',
                extraArgs = { '--no-deps' },
              },
            },
          },
          -- Load per-project rust-analyzer.json if present
          settings = function(project_root, default_settings)
            local settings = default_settings
            local ra_settings_file = project_root .. '/rust-analyzer.json'
            if vim.fn.filereadable(ra_settings_file) == 1 then
              local ok, json = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(ra_settings_file), '\n'))
              if ok and json then
                settings = vim.tbl_deep_extend('force', settings, json)
              end
            end
            return settings
          end,
        },
        tools = {
          float_win_config = { auto_focus = true },
        },
      }
    end,
    config = function()
      -- Rust test runner + RustLSP keybindings
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'rust',
        group = vim.api.nvim_create_augroup('RustKeymaps', { clear = true }),
        callback = function(ev)
          local runner = require 'custom.test-runner'
          local function buf_map(key, fn, desc)
            vim.keymap.set('n', key, fn, { buffer = ev.buf, desc = desc })
          end

          -- RustLSP keybindings
          buf_map('<Leader>rh', function() vim.cmd.RustLsp { 'hover', 'actions' } end, 'Rust: hover actions')
          buf_map('<Leader>rr', function() vim.cmd.RustLsp 'run' end, 'Rust: run')
          buf_map('<Leader>re', function() vim.cmd.RustLsp 'explainError' end, 'Rust: explain error')
          buf_map('<Leader>rd', function() vim.cmd.RustLsp 'renderDiagnostic' end, 'Rust: render diagnostic')

          -- Run nearest test
          buf_map('<Leader>tr', function()
            local name = get_nearest_test()
            if not name then
              vim.notify('No test function found at cursor', vim.log.levels.WARN)
              return
            end
            local root = find_cargo_root()
            if not root then
              vim.notify('No Cargo.toml found', vim.log.levels.WARN)
              return
            end
            runner.run(string.format('cargo test %s -- --nocapture', name), root)
          end, 'Test: run nearest')

          -- Run all tests in current file (by module path)
          buf_map('<Leader>tf', function()
            local root = find_cargo_root()
            if not root then
              vim.notify('No Cargo.toml found', vim.log.levels.WARN)
              return
            end
            -- Derive module path from file path: src/foo/bar.rs -> foo::bar
            local file = vim.fn.expand '%:p'
            local rel = file:sub(#root + 2) -- strip root + /
            -- Strip src/ prefix and .rs extension
            local mod_path = rel:gsub('^src/', ''):gsub('%.rs$', '')
            -- Convert / to ::, handle mod.rs and lib.rs/main.rs
            mod_path = mod_path:gsub('/mod$', ''):gsub('mod$', ''):gsub('lib$', ''):gsub('main$', '')
            mod_path = mod_path:gsub('/', '::')
            -- If empty (lib.rs/main.rs), run all tests; otherwise filter by module
            if mod_path == '' then
              runner.run('cargo test -- --nocapture', root)
            else
              runner.run(string.format('cargo test %s:: -- --nocapture', mod_path), root)
            end
          end, 'Test: run file')

          -- Run all tests in project
          buf_map('<Leader>ta', function()
            local root = find_cargo_root()
            if not root then
              vim.notify('No Cargo.toml found', vim.log.levels.WARN)
              return
            end
            runner.run('cargo test -- --nocapture', root)
          end, 'Test: run all')

          -- Common: rerun, close, stop
          runner.bind_common(ev.buf)
        end,
      })
    end,
  },

  -- Crates.nvim: Cargo.toml version management, hover info, completion
  {
    'saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    opts = {
      completion = {
        crates = { enabled = true },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },

  -- Rust + TOML treesitter parsers
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'rust', 'toml' })
      end
    end,
  },
}
