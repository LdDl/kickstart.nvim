return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  opts = {
    suggestion = {
      enabled = true,
      auto_trigger = true,
      keymap = {
        accept = '<Tab>',
        next = '<C-x>',
        prev = '<C-z>',
        accept_word = '<C-Right>',
        accept_line = '<C-Down>',
        dismiss = '<C-c>',
      },
    },
    -- Disable copilot's built-in completion panel (we use inline suggestions)
    panel = { enabled = false },
  },
}
