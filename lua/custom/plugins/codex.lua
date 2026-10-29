return {
  {
    'rhart92/codex.nvim',
    cmd = {
      'CodexToggle',
      'CodexOpen',
      'CodexFile',
      'CodexSelection',
      'CodexStop',
      'CodexLogin',
      'CodexLoginStatus',
    },
    keys = {
      { '<leader>aa', '<cmd>CodexToggle<CR>', desc = 'Toggle Codex' },
      { '<leader>ao', '<cmd>CodexOpen<CR>', desc = 'Open Codex' },
      { '<leader>af', '<cmd>CodexFile<CR>', desc = 'Add current file to Codex' },
      { '<leader>as', '<cmd>CodexSelection<CR>', mode = 'x', desc = 'Add selection to Codex' },
      { '<leader>ax', '<cmd>CodexStop<CR>', desc = 'Stop Codex session' },
      { '<leader>al', '<cmd>CodexLogin<CR>', desc = 'Sign in with ChatGPT workspace' },
      { '<leader>ai', '<cmd>CodexLoginStatus<CR>', desc = 'Codex login status' },
      { '<C-,>', '<cmd>CodexToggle<CR>', mode = { 'n', 't' }, desc = 'Toggle Codex' },
    },
    opts = function()
      return {
        split = 'vertical',
        size = 0.4,
        focus_after_send = true,
        -- Reuse the CLI's ChatGPT login, including the selected workspace.
        codex_cmd = { vim.fn.exepath 'codex', '-c', 'forced_login_method="chatgpt"' },
      }
    end,
    config = function(_, opts)
      local codex = require 'codex'
      codex.setup(opts)

      local function command(name, callback, desc, extra)
        vim.api.nvim_create_user_command(name, callback, vim.tbl_extend('force', { desc = desc }, extra or {}))
      end

      command('CodexToggle', codex.toggle, 'Show or hide Codex without stopping it')
      command('CodexOpen', codex.open, 'Open the Codex terminal')
      command('CodexStop', codex.close, 'Stop the Codex process')
      command('CodexFile', function()
        if vim.bo.modified then
          vim.notify('Save this file before sharing it with Codex; file context is read from disk.', vim.log.levels.WARN)
          return
        end
        codex.send_buffer()
      end, 'Add the saved current file to the Codex prompt')
      command('CodexSelection', function()
        local mode = vim.fn.mode()
        local active = mode:match('^[vV\22]') ~= nil
        local first = vim.fn.getpos(active and 'v' or "'<")
        local last = vim.fn.getpos(active and '.' or "'>")
        local selection_type = active and mode or vim.fn.visualmode()
        if first[2] == 0 or last[2] == 0 then
          vim.notify('Select some code before sharing it with Codex.', vim.log.levels.WARN)
          return
        end
        local lines = vim.fn.getregion(first, last, { type = selection_type, exclusive = vim.o.selection == 'exclusive' })
        local file = vim.api.nvim_buf_get_name(0)
        local context = string.format('File: %s:%d-%d\n\n%s', file ~= '' and file or '[No Name]',
          math.min(first[2], last[2]), math.max(first[2], last[2]), table.concat(lines, '\n'))
        -- Bracketed paste keeps multiline code in the composer until you submit it.
        codex.send('\27[200~' .. context .. '\27[201~', { submit = false })
      end, 'Add the visual selection to the Codex prompt', { range = true })

      command('CodexLogin', function()
        -- Keep browser/SSO sign-in in an interactive terminal. Credentials stay with Codex.
        vim.cmd 'botright 12split'
        local buffer = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(0, buffer)
        vim.bo[buffer].bufhidden = 'wipe'
        vim.fn.jobstart({ opts.codex_cmd[1], '-c', 'forced_login_method="chatgpt"', 'login' }, { term = true })
        vim.cmd 'startinsert'
      end, 'Sign in to Codex with your ChatGPT workspace in the browser')

      command('CodexLoginStatus', function()
        vim.system({ opts.codex_cmd[1], 'login', 'status' }, { text = true }, function(result)
          vim.schedule(function()
            local message = vim.trim((result.stdout or '') .. '\n' .. (result.stderr or ''))
            vim.notify(
              message ~= '' and message or 'No login status returned.',
              result.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN,
              { title = 'Codex login' }
            )
          end)
        end)
      end, 'Show the Codex CLI authentication status')
    end,
  },
  {
    'folke/which-key.nvim',
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { '<leader>a', group = 'Codex', mode = { 'n', 'x' } })
    end,
  },
}
