-- Shared terminal-based test runner for Go and Rust
-- Opens a terminal split at the bottom, shows the command and output
local M = {}

-- Store last test command for re-run (persists across calls)
M.last_test_cmd = nil

-- Close existing test output window if any
function M.close_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.w[win].is_test_runner then
      vim.api.nvim_win_close(win, true)
      return true
    end
  end
  return false
end

-- Stop running test process
function M.stop()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.w[win].is_test_runner then
      local buf = vim.api.nvim_win_get_buf(win)
      local job_id = vim.b[buf].terminal_job_id
      if job_id then
        vim.fn.jobstop(job_id)
      end
      return
    end
  end
end

-- Run a test command in a terminal split at the bottom
-- Shows the command as first line, then output
function M.run(test_cmd, dir)
  M.close_win()
  local full_cmd = string.format("cd %s && echo '$ %s' && echo '' && %s", vim.fn.shellescape(dir), test_cmd, test_cmd)
  M.last_test_cmd = full_cmd
  vim.cmd 'botright new | resize 15'
  vim.w[vim.api.nvim_get_current_win()].is_test_runner = true
  vim.fn.termopen(full_cmd)
  local buf = vim.api.nvim_get_current_buf()
  vim.keymap.set('n', 'q', function() M.close_win() end, { buffer = buf, nowait = true })
  vim.cmd 'wincmd p'
end

-- Re-run the last test command
function M.rerun()
  if M.last_test_cmd then
    M.close_win()
    vim.cmd 'botright new | resize 15'
    vim.w[vim.api.nvim_get_current_win()].is_test_runner = true
    vim.fn.termopen(M.last_test_cmd)
    local buf = vim.api.nvim_get_current_buf()
    vim.keymap.set('n', 'q', function() M.close_win() end, { buffer = buf, nowait = true })
    vim.cmd 'wincmd p'
  else
    vim.notify('No previous test run', vim.log.levels.WARN)
  end
end

-- Set up common keybindings (rerun, close, stop) for a buffer
function M.bind_common(ev_buf)
  local function buf_map(key, fn, desc)
    vim.keymap.set('n', key, fn, { buffer = ev_buf, desc = desc })
  end
  buf_map('<Leader>tl', M.rerun, 'Test: re-run last')
  buf_map('<Leader>to', M.close_win, 'Test: close output')
  buf_map('<Leader>tx', M.stop, 'Test: stop')
end

return M
