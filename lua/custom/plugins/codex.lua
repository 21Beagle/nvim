return {
  {
    'rhart92/codex.nvim',
    cmd = {
      'CodexToggle',
      'CodexOpen',
      'CodexSplit',
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
      { '<leader>as', '<cmd>CodexSplit<CR>', desc = 'Open Codex in a vertical split' },
      { '<leader>as', '<cmd>CodexSelection<CR>', mode = 'x', desc = 'Add selection to Codex' },
      { '<leader>ax', '<cmd>CodexStop<CR>', desc = 'Stop Codex session' },
      { '<leader>al', '<cmd>CodexLogin<CR>', desc = 'Sign in with ChatGPT workspace' },
      { '<leader>ai', '<cmd>CodexLoginStatus<CR>', desc = 'Codex login status' },
      { '<C-,>', '<cmd>CodexToggle<CR>', mode = { 'n', 't' }, desc = 'Toggle Codex' },
    },
    opts = function()
      return {
        split = 'float',
        size = 0.4,
        float = { width = 0.85, height = 0.85, border = 'rounded', title = ' Codex ' },
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

      local ui = require 'codex.ui'
      local function map_close()
        local buffer = ui.state.bufnr
        if buffer and vim.api.nvim_buf_is_valid(buffer) then
          vim.keymap.set('n', '<Esc><Esc>', function()
            if vim.api.nvim_get_current_win() == ui.state.winid then
              ui.close_window()
            end
          end, { buffer = buffer, desc = 'Hide Codex window' })
        end
      end
      vim.api.nvim_create_autocmd('BufEnter', {
        group = vim.api.nvim_create_augroup('CodexWindowKeys', { clear = true }),
        callback = function()
          -- The UI records its terminal buffer after opening the window.
          vim.schedule(map_close)
        end,
      })
      map_close()
      local function open_float()
        if ui.is_open() and ui.state.layout ~= 'float' then
          ui.close_window()
        end
        codex.open()
        ui.focus()
      end

      command('CodexToggle', function()
        if ui.is_open() then
          ui.close_window()
        else
          open_float()
        end
      end, 'Show or hide the floating Codex terminal without stopping it')
      command('CodexOpen', open_float, 'Open Codex in a floating window')
      command('CodexSplit', function()
        -- Move the existing terminal buffer so the Codex session stays alive.
        codex.open()
        if ui.state.layout ~= 'vertical' then
          ui.close_window()
          ui.open_window(vim.tbl_extend('force', opts, { split = 'vertical' }), ui.state.bufnr)
        end
        ui.focus()
        vim.cmd 'startinsert'
      end, 'Open Codex in a vertical split')
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
        local active = mode:match '^[vV\22]' ~= nil
        local first = vim.fn.getpos(active and 'v' or "'<")
        local last = vim.fn.getpos(active and '.' or "'>")
        local selection_type = active and mode or vim.fn.visualmode()
        if first[2] == 0 or last[2] == 0 then
          vim.notify('Select some code before sharing it with Codex.', vim.log.levels.WARN)
          return
        end
        local lines = vim.fn.getregion(first, last, { type = selection_type, exclusive = vim.o.selection == 'exclusive' })
        local file = vim.api.nvim_buf_get_name(0)
        local context = string.format(
          'File: %s:%d-%d\n\n%s',
          file ~= '' and file or '[No Name]',
          math.min(first[2], last[2]),
          math.max(first[2], last[2]),
          table.concat(lines, '\n')
        )
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
