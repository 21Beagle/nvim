return {
  {
    'mfussenegger/nvim-dap',
    event = 'BufReadPost',
    dependencies = {
      {
        'rcarriga/nvim-dap-ui',
        dependencies = {
          'nvim-neotest/nvim-nio',
        },
        opts = {},
        config = function(_, opts)
          local dap = require 'dap'
          local dapui = require 'dapui'

          require('custom.config.dap-ui-requests').setup(dap)

          dapui.setup(vim.tbl_deep_extend('force', opts or {}, {
            force_buffers = true,
            mappings = {
              expand = { '<CR>', 'o' },
              open = { 'g', 'p' },
              remove = { 'd', 'r' },
              edit = 'e',
              repl = 'K',
              toggle = 't',
              watch = 'a',
            },
            layouts = {
              {
                elements = {
                  { id = 'scopes', size = 1.0 },
                },
                size = 16,
                position = 'bottom',
              },
              {
                elements = {
                  { id = 'watches', size = 1.0 },
                },
                size = 16,
                position = 'bottom',
              },
              {
                elements = {
                  { id = 'stacks', size = 1.0 },
                },
                size = 70,
                position = 'right',
              },
              {
                elements = {
                  { id = 'breakpoints', size = 1.0 },
                },
                size = 70,
                position = 'right',
              },
            },
            floating = {
              border = 'rounded',
              mappings = {
                close = { 'q', '<Esc>' },
              },
            },
            render = {
              max_value_lines = 1,
            },
            controls = {
              enabled = true,
              element = 'scopes',
            },
          }))

          local function find_element_window(element_name)
            local element = dapui.elements[element_name]

            if not element then
              return nil
            end

            local ok, bufnr = pcall(element.buffer)

            if not ok or not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
              return nil
            end

            for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
              if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == '' then
                return win
              end
            end

            return nil
          end

          local function toggle_dapui_element(layout, element_name)
            dapui.toggle {
              layout = layout,
              reset = true,
            }

            vim.schedule(function()
              local win = find_element_window(element_name)

              if win and vim.api.nvim_win_is_valid(win) then
                pcall(vim.api.nvim_set_current_win, win)
              end
            end)
          end

          local element_layouts = { scopes = 1, watches = 2, stacks = 3, breakpoints = 4 }

          local function close_element_floats(element_name)
            local bufnr = dapui.elements[element_name].buffer()
            for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
              if vim.api.nvim_win_get_config(win).relative ~= '' then
                vim.api.nvim_win_close(win, true)
              end
            end
          end

          local function dock_dapui_element(element_name, toggle)
            close_element_floats(element_name)
            local args = { layout = element_layouts[element_name], reset = true }
            if toggle then
              dapui.toggle(args)
            else
              dapui.open(args)
            end
            local win = find_element_window(element_name)
            if win then
              vim.api.nvim_set_current_win(win)
            end
          end

          _G.float_dapui_element = function(element_name)
            dapui.float_element(element_name, {
              enter = true,
              position = 'center',
              title = 'Debug: ' .. element_name .. ' (<leader>dD: dock, q: close)',
              width = math.max(1, math.min(120, math.floor(vim.o.columns * 0.8))),
              height = math.max(1, math.min(24, math.floor(vim.o.lines * 0.7))),
            })
          end
          _G.dock_dapui_element = dock_dapui_element
          _G.dock_current_dapui = function()
            local element_name = vim.bo.filetype:match '^dapui_(.+)$'
            if element_layouts[element_name] and vim.api.nvim_win_get_config(0).relative ~= '' then
              dock_dapui_element(element_name, false)
            else
              vim.notify('Focus a Scopes, Watches, Call Stacks, or Breakpoints popup to dock it.', vim.log.levels.INFO)
            end
          end

          -- Give all debugger floats the same focus and dismissal behavior.
          vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
            group = vim.api.nvim_create_augroup('DebugPopupWindows', { clear = true }),
            callback = function(event)
              local bufnr = event.buf
              vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(bufnr) then
                  return
                end

                local filetype = vim.bo[bufnr].filetype
                if not (filetype:match '^dapui_' or filetype == 'dap-float') then
                  return
                end

                for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
                  if vim.api.nvim_win_get_config(win).relative ~= '' then
                    local function close_popup()
                      local current = vim.api.nvim_get_current_win()
                      if vim.api.nvim_win_get_config(current).relative ~= '' then
                        vim.api.nvim_win_close(current, true)
                      end
                    end

                    for _, key in ipairs { 'q', '<Esc>' } do
                      vim.keymap.set('n', key, close_popup, { buffer = bufnr, desc = 'Close debug popup' })
                    end

                    vim.api.nvim_set_current_win(win)
                    break
                  end
                end
              end)
            end,
          })

          local function close_dapui()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local bufnr = vim.api.nvim_win_get_buf(win)
              if vim.bo[bufnr].filetype:match '^dapui_' and vim.api.nvim_win_get_config(win).relative ~= '' then
                vim.api.nvim_win_close(win, true)
              end
            end
            pcall(function()
              dapui.close()
            end)
          end

          local function reset_dapui()
            close_dapui()

            vim.schedule(function()
              for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype:match '^dapui_' then
                  pcall(vim.api.nvim_buf_delete, bufnr, {
                    force = true,
                  })
                end
              end
            end)
          end

          _G.toggle_dapui_scopes = function()
            toggle_dapui_element(1, 'scopes')
          end

          _G.toggle_dapui_watches = function()
            toggle_dapui_element(2, 'watches')
          end

          _G.toggle_dapui_stacks = function()
            toggle_dapui_element(3, 'stacks')
          end

          _G.toggle_dapui_breakpoints = function()
            toggle_dapui_element(4, 'breakpoints')
          end

          _G.close_dapui = close_dapui
          _G.reset_dapui = reset_dapui

          vim.api.nvim_create_user_command('DapUiClose', close_dapui, {})
          vim.api.nvim_create_user_command('DapUiReset', reset_dapui, {})

          dap.listeners.before.event_terminated['dapui_config'] = close_dapui
          dap.listeners.before.event_exited['dapui_config'] = close_dapui

          local function set_dap_highlights()
            vim.api.nvim_set_hl(0, 'DapBreakpoint', {
              fg = '#ff5555',
            })

            vim.api.nvim_set_hl(0, 'DapBreakpointCondition', {
              fg = '#ffcc90',
            })

            vim.api.nvim_set_hl(0, 'DapBreakpointRejected', {
              fg = '#905555',
            })

            vim.api.nvim_set_hl(0, 'DapLogPoint', {
              fg = '#61afef',
            })

            vim.api.nvim_set_hl(0, 'DapStopped', {
              fg = '#ffcc90',
              bold = true,
            })

            vim.api.nvim_set_hl(0, 'DapStoppedLine', {
              bg = '#4a3f00',
              bold = true,
            })

            vim.fn.sign_define('DapBreakpoint', {
              text = '',
              texthl = 'DapBreakpoint',
              linehl = '',
              numhl = 'DapBreakpoint',
            })

            vim.fn.sign_define('DapBreakpointCondition', {
              text = '',
              texthl = 'DapBreakpointCondition',
              linehl = '',
              numhl = 'DapBreakpointCondition',
            })

            vim.fn.sign_define('DapBreakpointRejected', {
              text = '',
              texthl = 'DapBreakpointRejected',
              linehl = '',
              numhl = 'DapBreakpointRejected',
            })

            vim.fn.sign_define('DapLogPoint', {
              text = '',
              texthl = 'DapLogPoint',
              linehl = '',
              numhl = 'DapLogPoint',
            })

            vim.fn.sign_define('DapStopped', {
              text = '󰁕',
              texthl = 'DapStopped',
              linehl = 'DapStoppedLine',
              numhl = 'DapStoppedLine',
            })
          end

          set_dap_highlights()

          vim.api.nvim_create_autocmd('ColorScheme', {
            callback = set_dap_highlights,
          })

          vim.opt.mouse = 'a'
          vim.opt.signcolumn = 'yes'

          vim.keymap.set('n', '<LeftMouse>', function()
            local mouse = vim.fn.getmousepos()

            if mouse.winid == 0 then
              return '<LeftMouse>'
            end

            local win = mouse.winid
            local bufnr = vim.api.nvim_win_get_buf(win)

            if vim.bo[bufnr].buftype ~= '' then
              return '<LeftMouse>'
            end

            local wininfo = vim.fn.getwininfo(win)[1]

            if not wininfo then
              return '<LeftMouse>'
            end

            if mouse.wincol <= wininfo.textoff then
              vim.api.nvim_set_current_win(win)
              vim.api.nvim_win_set_cursor(win, { mouse.line, 0 })
              require('dap').toggle_breakpoint()
              return ''
            end

            return '<LeftMouse>'
          end, {
            expr = true,
            silent = true,
            desc = 'Toggle DAP breakpoint from gutter',
          })
        end,
      },
      {
        'theHamsta/nvim-dap-virtual-text',
        opts = {},
      },
    },
    keys = {
      {
        '<F5>',
        function()
          require('dap').continue()
        end,
        desc = 'Debug: Start/Continue',
      },
      {
        '<S-F5>',
        function()
          require('dap').terminate()
        end,
        desc = 'Debug: Stop',
      },
      {
        '<F17>',
        function()
          require('dap').terminate()
        end,
        desc = 'Debug: Stop',
      },
      {
        '<C-S-F5>',
        function()
          require('dap').restart()
        end,
        desc = 'Debug: Restart',
      },
      {
        '<F9>',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Debug: Toggle Breakpoint',
      },
      {
        '<S-F9>',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Conditional Breakpoint',
      },
      {
        '<F21>',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Conditional Breakpoint',
      },
      {
        '<C-F9>',
        function()
          require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log point message: ')
        end,
        desc = 'Debug: Logpoint',
      },
      {
        '<F10>',
        function()
          require('dap').step_over()
        end,
        desc = 'Debug: Step Over',
      },
      {
        '<F11>',
        function()
          require('dap').step_into()
        end,
        desc = 'Debug: Step Into',
      },
      {
        '<S-F11>',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: Step Out',
      },
      {
        '<F23>',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: Step Out',
      },
      {
        '<C-F10>',
        function()
          require('dap').run_to_cursor()
        end,
        desc = 'Debug: Run to Cursor',
      },
      {
        '<F8>',
        function()
          require('dap').down()
        end,
        desc = 'Debug: Down Stack',
      },
      {
        '<S-F8>',
        function()
          require('dap').up()
        end,
        desc = 'Debug: Up Stack',
      },
      {
        '<F20>',
        function()
          require('dap').up()
        end,
        desc = 'Debug: Up Stack',
      },
      {
        '<F7>',
        function()
          _G.toggle_dapui_scopes()
        end,
        desc = 'Debug: Toggle Scopes',
      },
      {
        '<S-F7>',
        function()
          _G.close_dapui()
        end,
        desc = 'Debug: Close UI',
      },
      {
        '<F19>',
        function()
          _G.close_dapui()
        end,
        desc = 'Debug: Close UI',
      },
      {
        '<leader>dv',
        function()
          _G.float_dapui_element('scopes')
        end,
        desc = 'Debug: Scopes: Float',
      },
      {
        '<leader>dV',
        function()
          _G.dock_dapui_element('scopes', true)
        end,
        desc = 'Debug: Scopes: Dock',
      },
      {
        '<leader>dw',
        function()
          _G.float_dapui_element('watches')
        end,
        desc = 'Debug: Watches: Float',
      },
      {
        '<leader>dW',
        function()
          _G.dock_dapui_element('watches', true)
        end,
        desc = 'Debug: Watches: Dock',
      },
      {
        '<leader>dc',
        function()
          _G.float_dapui_element('stacks')
        end,
        desc = 'Debug: Call Stacks: Float',
      },
      {
        '<leader>dC',
        function()
          _G.dock_dapui_element('stacks', true)
        end,
        desc = 'Debug: Call Stacks: Dock',
      },
      {
        '<leader>dp',
        function()
          _G.float_dapui_element('breakpoints')
        end,
        desc = 'Debug: Breakpoints: Float',
      },
      {
        '<leader>dP',
        function()
          _G.dock_dapui_element('breakpoints', true)
        end,
        desc = 'Debug: Breakpoints: Dock',
      },
      {
        '<leader>de',
        function()
          local session = require('dap').session()
          if not session or not session.stopped_thread_id or not session.current_frame then
            vim.notify('Pause at a breakpoint and select a stack frame before evaluating.', vim.log.levels.WARN)
            return
          end

          -- Each hover owns its buffer, so late replies cannot overwrite another expression.
          local view = require('dap.ui.widgets').hover(nil, { border = 'rounded' })
          for _, key in ipairs { 'q', '<Esc>' } do
            vim.keymap.set('n', key, function()
              view.close()
            end, { buffer = view.buf, desc = 'Close debug evaluation' })
          end
        end,
        desc = 'Debug: Evaluate',
      },
      {
        '<leader>dj',
        function()
          require('dap').down()
        end,
        desc = 'Debug: Down Stack',
      },
      {
        '<leader>dk',
        function()
          require('dap').up()
        end,
        desc = 'Debug: Up Stack',
      },
      {
        '<leader>dD',
        function()
          _G.dock_current_dapui()
        end,
        desc = 'Debug: Dock Popup',
      },
      {
        '<leader>du',
        function()
          _G.close_dapui()
        end,
        desc = 'Debug: Close UI',
      },
    },
    config = function()
      local dap = require 'dap'
      local dap_breakpoints = require 'dap.breakpoints'
      local store_path = vim.fn.stdpath('state') .. '/dap-breakpoints.json'
      local stored_breakpoints = {}
      local restoring = false
      local mutation_depth = 0

      local function normalize_path(path)
        if not path or path == '' then
          return nil
        end

        return vim.fs.normalize(vim.fn.fnamemodify(path, ':p')):lower()
      end

      local function read_store()
        if vim.fn.filereadable(store_path) ~= 1 then
          stored_breakpoints = {}
          return
        end

        local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(store_path), '\n'))

        if ok and type(decoded) == 'table' then
          stored_breakpoints = decoded
        else
          stored_breakpoints = {}
        end
      end

      local function write_store()
        vim.fn.mkdir(vim.fn.fnamemodify(store_path, ':h'), 'p')

        local ok, encoded = pcall(vim.json.encode, stored_breakpoints)

        if not ok then
          return
        end

        vim.fn.writefile({ encoded }, store_path)
      end

      local function can_persist_buffer(bufnr)
        if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
          return false
        end

        if vim.bo[bufnr].buftype ~= '' then
          return false
        end

        return normalize_path(vim.api.nvim_buf_get_name(bufnr)) ~= nil
      end

      local function sync_buffer_breakpoints(bufnr)
        if restoring or not can_persist_buffer(bufnr) then
          return
        end

        local path = normalize_path(vim.api.nvim_buf_get_name(bufnr))
        local all_breakpoints = dap_breakpoints.get(bufnr)
        local buffer_breakpoints = all_breakpoints[bufnr] or {}

        if #buffer_breakpoints == 0 then
          stored_breakpoints[path] = nil
          write_store()
          return
        end

        local result = {}

        for _, bp in ipairs(buffer_breakpoints) do
          result[#result + 1] = {
            line = bp.line,
            condition = bp.condition,
            hitCondition = bp.hitCondition,
            logMessage = bp.logMessage,
          }
        end

        table.sort(result, function(a, b)
          return a.line < b.line
        end)

        stored_breakpoints[path] = result
        write_store()
      end

      local function restore_buffer_breakpoints(bufnr)
        if not can_persist_buffer(bufnr) then
          return
        end

        local path = normalize_path(vim.api.nvim_buf_get_name(bufnr))
        local saved = stored_breakpoints[path]

        if not saved or #saved == 0 then
          return
        end

        local existing = dap_breakpoints.get(bufnr)[bufnr]

        if existing and #existing > 0 then
          return
        end

        local line_count = vim.api.nvim_buf_line_count(bufnr)
        restoring = true

        for _, bp in ipairs(saved) do
          if type(bp.line) == 'number' and bp.line >= 1 and bp.line <= line_count then
            dap_breakpoints.set({
              condition = bp.condition,
              hit_condition = bp.hitCondition,
              log_message = bp.logMessage,
            }, bufnr, bp.line)
          end
        end

        restoring = false
      end

      local function schedule_sync(bufnr)
        if restoring then
          return
        end

        vim.schedule(function()
          sync_buffer_breakpoints(bufnr)
        end)
      end

      read_store()

      local original_remove = dap_breakpoints.remove
      dap_breakpoints.remove = function(bufnr, lnum)
        mutation_depth = mutation_depth + 1
        local removed = original_remove(bufnr, lnum)
        mutation_depth = mutation_depth - 1

        if removed and mutation_depth == 0 then
          schedule_sync(bufnr)
        end

        return removed
      end

      local original_toggle = dap_breakpoints.toggle
      dap_breakpoints.toggle = function(opts, bufnr, lnum)
        local target_buf = bufnr or vim.api.nvim_get_current_buf()

        mutation_depth = mutation_depth + 1
        local result = original_toggle(opts, bufnr, lnum)
        mutation_depth = mutation_depth - 1

        if mutation_depth == 0 then
          schedule_sync(target_buf)
        end

        return result
      end

      local original_clear = dap_breakpoints.clear
      dap_breakpoints.clear = function(...)
        local result = original_clear(...)

        if not restoring then
          stored_breakpoints = {}
          write_store()
        end

        return result
      end

      vim.api.nvim_create_autocmd('BufReadPost', {
        callback = function(args)
          restore_buffer_breakpoints(args.buf)
        end,
      })

      vim.api.nvim_create_autocmd('BufWritePost', {
        callback = function(args)
          sync_buffer_breakpoints(args.buf)
        end,
      })

      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            sync_buffer_breakpoints(bufnr)
          end
        end,
      })

      vim.schedule(function()
        restore_buffer_breakpoints(vim.api.nvim_get_current_buf())
      end)

      vim.api.nvim_create_user_command('DapBreakpointsSave', function()
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          sync_buffer_breakpoints(bufnr)
        end

        vim.notify('DAP breakpoints saved to ' .. store_path)
      end, {})

      vim.api.nvim_create_user_command('DapBreakpointsFile', function()
        vim.notify(store_path)
      end, {})

      local function reset_dap()
        pcall(function()
          dap.terminate()
        end)

        pcall(function()
          dap.disconnect {
            terminateDebuggee = true,
          }
        end)

        pcall(function()
          _G.close_dapui()
        end)

        pcall(function()
          dap.repl.close()
        end)
      end

      vim.api.nvim_create_user_command('DapReset', reset_dap, {})

    end,
  },
}
